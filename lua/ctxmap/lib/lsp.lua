local M = {}
local lsp = vim.lsp

--- Check if any LSP client is attached to the current buffer.
---@param name string? The name of the LSP client to check for. If nil, check if any client is attached.
---@return boolean
function M.attached(name)
  local filter = { bufnr = 0 }
  if name then
    filter.name = name
  end
  return #lsp.get_clients(filter) > 0
end

--- Check if any LSP client is attached to the current buffer.
---@param method string The LSP method to check for.
---@return boolean
function M.has_method(method)
  return #lsp.get_clients({ bufnr = 0, method = method }) > 0
end

--- Check if any active LSP client for the buffer supports a specific capability.
---@param capability string The capability key (e.g., 'definitionProvider', 'renameProvider', 'codeActionProvider')
---@return boolean
function M.has_capability(capability)
  return vim.iter(lsp.get_clients({ bufnr = 0 }) or {}):any(function(client)
    return client.server_capabilities[capability]
  end)
end

return M
