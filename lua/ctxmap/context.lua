local Cache = setmetatable({}, { __mode = 'v' })
local Context = {}

local M = {}

local CtxLibrary = setmetatable({}, {
  __index = function(env, k)
    if Context[k] or rawget(env, k) then
      return Context[k] or env[k]
    end

    local lib = require('ctxmap.library').get(k)
    if not lib then
      return _G[k]
    end
    return lib
  end,
})

local ctx_str = 'return function(lhs, map) return %s end'

---@param str string
---@return ctxmap.ctx.fn
local function _eval(str)
  local ctx = assert(loadstring(ctx_str:format(str)))()
  setfenv(ctx, CtxLibrary)
  return ctx
end

---@param ctx string|function
---@return ctxmap.ctx.fn
function M.get(ctx)
  if type(ctx) == 'function' then
    return ctx
  end

  local circle = { [ctx] = true }
  -- resolve string def
  local definition = ctx
  while type(Context[ctx]) == 'string' and ctx ~= Context[ctx] do
    ctx = Context[ctx]
    if circle[ctx] then
      error('Circular context definition: ' .. definition)
    end
    circle[ctx] = true
  end

  -- have string def now. Check for it
  if Context[ctx] or Cache[ctx] then
    Context[definition] = Context[ctx] or Cache[ctx]
    return Context[definition]

    -- check library for a.b
  else
    local _ctx = require('ctxmap.library').lookup(ctx)
    if type(_ctx) == 'string' then
      _ctx = _eval(_ctx)
    end
    if _ctx then
      return _ctx
    end
  end

  if ctx:match('^[ %w_.]+$') then
    return function()
      error(('Context not found: "%s"'):format(definition))
    end
  end

  -- eval string def
  ctx = _eval(ctx)
  if Context[definition] then
    -- store it if it's an added context
    Context[definition] = ctx
  else
    -- otherwise just until the map disappears
    Cache[definition] = ctx
  end

  return Context[definition] or Cache[definition]
end

function M.add(name, ctx)
  vim.validate('name', name, 'string')
  vim.validate('ctx', ctx, { 'string', 'function', 'table' })

  if type(ctx) == 'table' then
    local lib = setmetatable({}, getmetatable(ctx))
    for k, v in pairs(ctx) do
      lib[k] = v
      if type(v) == 'string' then
        lib[k] = function(...)
          lib[k] = M.get(v)
          return lib[k](...)
        end
      end
    end
    require('ctxmap.library').add(name, lib)
  else
    Context[name] = ctx
  end
end

return M
