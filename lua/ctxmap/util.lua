local M = {}

M.log = require('ctxmap.util.log')
M.keymap = require('ctxmap.util.keymap')

---@type table<string, vim.regex>
M.compiled_vim_regexes = (function()
  -- from neovim runtime for treesitter predicates
  local magic_prefixes = { ['\\v'] = true, ['\\m'] = true, ['\\M'] = true, ['\\V'] = true }
  local function check_magic(str)
    if string.len(str) < 2 or magic_prefixes[string.sub(str, 1, 2)] then
      return str
    end
    return '\\v' .. str
  end

  local compiled_vim_regexes = setmetatable({}, {
    __index = function(t, pattern)
      local res = vim.regex(check_magic(pattern))
      rawset(t, pattern, res)
      return res
    end,
  })

  return compiled_vim_regexes
end)()

return M
