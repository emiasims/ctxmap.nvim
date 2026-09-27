local M = {}
local diagnostic = vim.diagnostic

M.is_enabled = vim.diagnostic.is_enabled

--- Check if the current buffer has diagnostics.
---@param severity? number|table Vim diagnostic severity level(s) (e.g., vim.diagnostic.severity.ERROR)
---@return boolean
function M.in_buffer(severity)
  local config = severity and { severity = severity } or {}
  return #diagnostic.get(0, config) > 0
end

--- Check if there are diagnostics at the current cursor position.
---@param severity? number|table Vim diagnostic severity level(s)
---@return boolean
function M.at_cursor(severity)
  local config = severity and { severity = severity } or {}
  local pos = vim.api.nvim_win_get_cursor(0)
  -- diagnostic.get uses 0-based line index
  return #diagnostic.get(0, vim.tbl_extend('force', config, { lnum = pos[1] - 1 })) > 0
end

return M
