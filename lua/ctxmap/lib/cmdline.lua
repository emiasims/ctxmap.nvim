local M = {}

function M.start(lhs, keymap)
  if keymap.mode == 'ca' then
    return M.type(':') and vim.fn.getcmdline():sub(1, #lhs) == lhs
  end
  return M.type(':') and vim.fn.getcmdpos() == 1
end

function M.type(t)
  if t then
    return vim.fn.getcmdtype() == t
  end
  return vim.fn.getcmdtype()
end

function M.compltype(t)
  if t then
    return vim.fn.getcmdcompltype() == t
  end
  return vim.fn.getcmdcompltype()
end

M.completing = function()
  return M.compltype('command')
end

function M.parsed()
  local cmdline = vim.fn.getcmdline()
  return vim.api.nvim_parse_cmd(cmdline, {})
end

function M.args(n)
  local args = M.parsed().args
  return n and args[n] or args
end

return M
