local Util = require('ctxmap.util')

local M = {}

-- This table holds the callbacks for the keymap weakly, so when the keymap is
-- removed, the callback can be garbage collected. The functions here
-- hold references to the keymap definitions in Keymaps.
---@type table<string, function>
local Callbacks = setmetatable({}, { __mode = 'v' })

---@type table<string, ctxmap.keymap>
local Keymaps = setmetatable({}, { __mode = 'v' })

--- Get a specific keymap definition by its mode, lhs, and buffer.
---@param mode string The keymap mode (e.g., 'n', 'v', 'i').
---@param lhs string The left-hand side of the keymap.
---@param buffer? number|boolean The buffer number (true for current, number for specific, nil for global).
---@return ctxmap.keymap?
function M.get(mode, lhs, buffer)
  local id = Util.keymap.id(mode, lhs, buffer)
  return Keymaps[id]
end

--- Internal function to set a single, resolved keymap definition.
--- This handles merging with existing definitions and setting the final Neovim keymap.
---@param map ctxmap.resolved.keymap A single resolved keymap definition from Util.keymap.resolve.
function M._set(map)
  ---@cast map ctxmap.keymap
  map.id = map.id or Util.keymap.id(map.mode, map.lhs)

  if map.opts.ctxmap.clear then
    Callbacks[map.id] = nil
    Keymaps[map.id] = nil
  end

  -- Resolve keymap merging if necessary
  if Keymaps[map.id] then
    if not vim.deep_equal(Keymaps[map.id].opts, map.opts) then
      map.opts = vim.tbl_deep_extend('force', Keymaps[map.id].opts, map.opts)
    end
    -- TODO: Add logic to remove duplicate contexts/rules if necessary.
    vim.list_extend(Keymaps[map.id].rules, map.rules)
    map = Keymaps[map.id]
  else
    Keymaps[map.id] = map
  end

  -- Resolve default
  if not map.default and map.opts.keymap.buffer then
    local global = Util.keymap.get(map.lhs, map.mode, false)
    if global then
      local rhs = global.rhs or global.callback
      map.default = {
        rhs = global.rhs or global.callback,
        opts = Util.keymap.opts.rule(global),
      }
      map.default.opts.buffer = map.opts.rule.buffer
    end
  end
  if not map.default then
    local default = map.lhs
    if map.mode:match('^[cis]') and default:match('^%W$') then
      -- if the default is <Space> or <Cr> or <Tab>, those keys typically trigger
      -- abbreviations. To maintain that behavior, we need to use <C-]>
      default = '<C-]>' .. default
    end
    map.default = { rhs = default, opts = map.opts.rule }
  end

  -- Resolve description
  local description = map.opts.keymap.desc
  if type(description) == 'function' then
    description = map.opts.keymap.desc(map)
  elseif not description then
    local desc = {}
    local max_len = 10
    for _, rule in ipairs(map.rules) do
      local ctx_str = type(rule.ctx) == 'string' and rule.ctx or vim.inspect(rule.ctx)
      local rhs_str = type(rule.rhs) == 'string' and rule.rhs or vim.inspect(rule.rhs)
      table.insert(desc, { ctx_str, rhs_str })
      max_len = math.max(max_len, #ctx_str)
    end
    local default = type(map.default.rhs) == 'string' and vim.fn.keytrans(vim.keycode(map.default.rhs))
      or vim.inspect(map.default.rhs)
    table.insert(desc, { 'default', default })
    for i, t in ipairs(desc) do
      desc[i] = ('%s%s : %s'):format(t[1], (' '):rep(max_len - #t[1]), t[2])
    end
    table.insert(desc, 1, ('context %s: rhs'):format((' '):rep(max_len - 7)))
    description = table.concat(desc, '\n\t\t ')
  end

  if not Callbacks[map.id] then
    -- buffer-local mappings need to be different, or deleted. else goofy bugs
    -- could also just clear the mapping if it exists..
    local PLUG = ('<Plug>(ctxmap-' .. (map.opts.keymap.buffer and 'buf-res)' or 'res)'))
    Callbacks[map.id] = function()
      if vim.g.ctxmap_debug then
        Util.keymap.check(map)
        vim.g.ctxmap_debug = nil
        return '<Ignore>'
      end

      ---@type ctxmap.rule|ctxmap.default.rule
      local res = map.default

      for _, rule in ipairs(map.rules) do
        if not rule._ctx and type(rule.ctx) ~= 'function' then
          rule._ctx = require('ctxmap.context').get(rule.ctx)
        end
        local ctx = rule._ctx or rule.ctx --[[@as function]]

        local ok, val = pcall(ctx, map.lhs, map)
        if not ok then
          Util.log.error_once('ctxmap: error in context function %s: \n%s', rule.ctx, val)
        elseif val then
          res = rule
          break
        end
      end

      Util.log.trace('Setting temporary <Plug> mapping: rhs=%s', res.rhs)
      vim.keymap.set(map.mode:sub(1, 1), PLUG, res.rhs, res.opts)

      -- eat abbr triggers
      if map.mode:sub(2) == 'a' and res.eat then
        local char = vim.fn.getchar(1, { number = false })
        if char:match(res.eat) then
          vim.fn.getchar(0)
        end
      end

      return PLUG
    end
  end

  -- save og description and apply new one
  map.opts.keymap.desc, description = description, map.opts.keymap.desc
  vim.keymap.set(map.mode, map.lhs, Callbacks[map.id], map.opts.keymap)
  -- restore description
  map.opts.keymap.desc = description
end

---@param spec ctxmap.spec.keys The keymap specification (single, list, or multimap).
---@param opts? ctxmap.opts.keymap Default options to apply.
local function resolve_and_set(spec, opts)
  ---@type boolean, any
  local ok, m = pcall(Util.keymap.resolve, spec, opts)
  if not ok then
    Util.log.error('unable to resolve spec: %s\nopts: %s', spec, opts)
  end
  local keymaps = m
  for _, t in ipairs(keymaps) do
    ok, m = pcall(M._set, t)
    if not ok then
      Util.log.error('failed setting keymap "%s"\n%s', t.id, m)
    end
  end
end

--- Public function to define a context keymap. Clears any previous definition by default.
---@param mode string|string[] The mode(s) for the keymap (e.g., 'n', {'n', 'v'}).
---@param lhs string The left-hand side of the keymap.
---@param rules ctxmap.spec.rule|ctxmap.spec.rule[] The context rules.
---@param opts? ctxmap.opts.keymap Additional options for the keymap.
function M.set(mode, lhs, rules, opts)
  ---@type ctxmap.spec.keymap
  local spec = opts and vim.deepcopy(opts) or {}
  spec[1], spec[2], spec.mode = lhs, rules, mode
  resolve_and_set(spec)
end

--- Public function to add rules to an existing context keymap or define a new one without clearing.
---@param mode string|string[] The mode(s) for the keymap.
---@param lhs string The left-hand side of the keymap.
---@param rules ctxmap.spec.rule|ctxmap.spec.rule[] The context rules to add.
---@param opts? ctxmap.opts.keymap Additional options for the keymap.
function M.add(mode, lhs, rules, opts)
  opts = opts or {}
  opts.clear = false
  M.set(mode, lhs, rules, opts)
end

--- Public function to define multiple context keymaps from a structured table.
---@param keys ctxmap.spec.keys A table containing multiple keymap specifications.
function M.sets(keys)
  resolve_and_set(keys)
end

return M
