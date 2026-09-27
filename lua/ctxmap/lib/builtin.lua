local M = {}

function M.always()
  return true
end

function M.never()
  return false
end

function M.count()
  return vim.v.count > 0
end

M.api = vim.api

local function accessor(vimopt)
  return setmetatable({}, {
    __index = function(t, option)
      local _not, opt = option:match('^(no)(%w+)$')
      opt = opt or option
      local metatype = type(vimopt[opt]._value)
      if metatype == 'boolean' and _not then
        t[option] = function()
          return not vimopt[opt]:get()
        end
      else
        assert(not _not, 'invalid option: ' .. option)
        t[option] = function()
          return vimopt[opt]:get()
        end
      end
      return t[option]
    end,
  })
end

M.opt = accessor(vim.opt)
M.opt_local = accessor(vim.opt_local)
M.opt_global = accessor(vim.opt_global)

M.fn = (function()
  local bool_funcs

  local function get_bool_funcs()
    local funlist = vim.api.nvim_get_runtime_file('doc/usr_41.txt', false)[1]
    local file = assert(io.open(funlist, 'r')) -- should always work..
    local bool_fns = {}
    for line in file:lines() do
      local fn = line:match('^%s+([_%w]+)%(%)%s+check')
      if fn then
        bool_fns[fn] = true
      end
      if #bool_fns > 25 and line:match('^====') then
        break
      end
    end
    file:close()
    return bool_fns
  end

  return setmetatable({}, {
    __index = function(t, name)
      bool_funcs = bool_funcs or get_bool_funcs()

      -- do the thing
      t[name] = vim.fn[name]
      if bool_funcs[name] then
        local f = t[name]
        t[name] = function(...)
          return f(...) ~= 0
        end
      end
      return t[name]
    end,
  })
end)()

M.abbr = {
  trigger = function(pat, plain)
    local trigger = vim.fn.getchar(1, { number = false })
    return (plain and trigger == pat) or (not plain and trigger:match(pat))
  end
}


return M
