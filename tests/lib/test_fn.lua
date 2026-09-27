require('tests.global')
local Fn = require('ctxmap.library').get('fn')

local T = new_set()
T.fn = new_set()

T.fn.bool = function()
  local file = vim.fn.tempname()
  vim.cmd.write({ file, mods = { emsg_silent = true } })
  eq[true](Fn.filereadable(file))
  vim.fn.delete(file)
  eq[false](Fn.filereadable(file))
end

T.fn.func = function()
  vim.api.nvim_buf_set_lines(0, 0, 1, false, { 'hello world' })
  eq(Fn.getline(1), 'hello world')
end

return T
