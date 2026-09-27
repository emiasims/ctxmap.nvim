local M = {}

---@return number?
M.buf = function(buf)
  if buf == true or buf == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return buf or nil
end

local Opts = {}
M.opts = Opts

---@return ctxmap.opts
Opts.all = function(...)
  local opts = vim.tbl_extend('force', {}, ...)
  for k in pairs(opts) do
    if type(k) == 'number' then
      opts[k] = nil
    end
  end
  return opts
end

Opts.ctxmap = function(...)
  local opts = vim.tbl_extend('force', {}, ...)
  return {
    dotrepeat = opts.dotrepeat or true,
    count = opts.count or true,
    clear = opts.clear or opts.clear == nil,
  }
end

---@return vim.keymap.set.Opts
Opts.keymap = function(...)
  local opts = vim.tbl_extend('force', {}, ...)
  return {
    expr = true,
    remap = true,
    nowait = opts.nowait,
    unique = opts.unique,
    silent = opts.silent,
    buffer = opts.buffer,
    desc = opts.desc,
    replace_keycodes = opts.replace_keycodes,
  }
end

---@return ctxmap.opts.rule
Opts.rule = function(...)
  local opts = vim.tbl_extend('force', {}, ...)
  return {
    noremap = opts.noremap,
    remap = opts.remap,
    expr = opts.expr,
    silent = opts.silent,
    desc = opts.desc,
    buffer = opts.buffer,
  }, opts.eat
end

local function _key(k)
  return vim.fn.keytrans(vim.keycode(k))
end

function M.get(lhs, mode, buffer)
  mode = mode or 'n'

  local keymaps
  if buffer then
    keymaps = vim.api.nvim_buf_get_keymap(buffer, mode)
  else
    keymaps = vim.api.nvim_get_keymap(mode)
  end

  lhs = _key(lhs)
  return vim.iter(keymaps):find(function(km)
    return _key(km.lhs) == lhs
  end)
end

function M.check(lhs, mode, buffer)
  local map = lhs
  if type(lhs) == 'string' then
    map = require('ctxmap.keymap').get(mode, lhs, buffer)
  end
  local res = {}
  for i, rule in ipairs(map.rules) do
    if not rule._ctx and type(rule.ctx) ~= 'function' then
      rule._ctx = require('ctxmap.context').get(rule.ctx)
    end
    local ctx = rule._ctx or rule.ctx

    local desc = rule.opts.desc or rule.ctx
    if type(desc) == 'function' then
      desc = rule.opts.desc(map)
    end
    table.insert(res, ('(%d) %s: %s'):format(i, desc, ctx(map.lhs, map) and true))
  end
  local Log = require('ctxmap.util.log')
  local level = Log.level
  Log.set_level(vim.log.levels.DEBUG)
  Log.debug('Context evaluation for "%s" in "%s" mode:\n%s', map.lhs, map.mode, table.concat(res, '\n'))
  Log.set_level(level)
end

function M.evals_to(lhs, mode, buffer)
  buffer = buffer == true and 0 or buffer
  mode = mode or 'n'
  local keymap = M.get(lhs, mode, buffer)
  if not keymap then
    error(string.format('No mapping found for "%s" in "%s" mode', lhs, mode))
  end
  keymap = M.get(keymap.callback(), mode, buffer)
  return keymap.rhs or keymap.callback, keymap
end

---@param mode string
---@param lhs string
---@param buffer? number|boolean
---@return string
function M.id(mode, lhs, buffer)
  lhs = vim.fn.keytrans(vim.keycode(lhs))
  buffer = M.buf(buffer)
  if buffer then
    return string.format('%s %s (%d)', mode, lhs, buffer)
  end
  return string.format('%s %s', mode, lhs)
end

---@param rule ctxmap.spec.rule
local function _normalize_rule(rule, km_opts)
  local rhs, ctx, opts, eat
  if type(rule) ~= 'table' then
    rhs = rule
    ctx = km_opts.ctx
    eat = km_opts.eat
    opts = Opts.rule(km_opts)
  elseif type(rule[2]) == 'table' then -- { ctx, rhs_table }
    ctx = rule[1]
    rhs = rule[2][1]
    opts = Opts.rule(km_opts, rule, rule[2])
    eat = rule[2].eat or km_opts.eat
  else -- { ctx, rhs }
    ctx, rhs = unpack(rule)
    eat = rule.eat or km_opts.eat
    opts = Opts.rule(km_opts, rule)
  end
  return { rhs = rhs, ctx = ctx, opts = opts, eat = eat }
end

local function _resolve(spec, opts)
  -- todo default
  local resolved = {}
  opts = Opts.all(spec, opts or {})
  if type(spec[1]) == 'string' then
    local lhs = spec[1] --[[@as string]]
    local mode = spec.mode or opts.mode or { 'n' }

    local map_opts = {
      ctxmap = Opts.ctxmap(opts),
      keymap = Opts.keymap(opts),
      rule = Opts.rule(opts),
    }

    if type(mode) == 'string' then
      mode = { mode }
    end

    local rules = spec[2]
    if opts.ctx and type(rules) ~= 'table' then
      rules = { _normalize_rule(spec[2], opts) }
    elseif #rules == 2 and (type(rules[1]) == 'string' or type(rules[1]) == 'function') then
      rules = { _normalize_rule(rules, opts) }
    else
      for i, rule in ipairs(rules) do
        rules[i] = _normalize_rule(rule, opts)
      end
    end

    local default
    if spec.default then
      default = _normalize_rule(spec.default, opts)
    end

    for _, m in ipairs(mode) do
      table.insert(resolved, {
        lhs = lhs,
        mode = m,
        rules = rules,
        opts = map_opts,
        default = default,
      })
    end
  else
    opts = Opts.all(spec, opts)
    for _, s in ipairs(spec) do
      vim.list_extend(resolved, _resolve(s, opts))
    end
  end

  return resolved
end

---@param spec ctxmap.spec.keys
function M.resolve(spec)
  return _resolve(spec)
end

return M
