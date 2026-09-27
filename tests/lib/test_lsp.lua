require('tests.global')
local Lsp = require('ctxmap.library').get('lsp')
local api = vim.api
local lsp = vim.lsp

local Clients, lsp_get_clients

local T = new_set({
  hooks = {
    pre_once = function()
      lsp_get_clients = lsp.get_clients
      ---@diagnostic disable-next-line: duplicate-set-field
      lsp.get_clients = function()
        return Clients
      end
    end,
    post_once = function()
      lsp.get_clients = lsp_get_clients
    end,
    pre_case = function()
      api.nvim_buf_set_lines(0, 0, -1, false, { 'line 1', 'line 2' })
      api.nvim_win_set_cursor(0, { 1, 0 }) -- Start at beginning of buffer
    end,
  },
})

T.lsp = new_set()

T.lsp.attached = function()
  Clients = {}
  eq[false](Lsp.attached())
  Clients = { { id = 1, name = 'test_lsp' } }
  eq[true](Lsp.attached())
end

T.lsp.has_capability = new_set()
T.lsp.has_capability['basic'] = function()
  Clients = { { id = 1, name = 'test', server_capabilities = {} } }
  eq[false](Lsp.has_capability('definitionProvider'))
  Clients = { { id = 1, name = 'test', server_capabilities = { definitionProvider = true } } }
  eq[true](Lsp.has_capability('definitionProvider'))
  eq[false](Lsp.has_capability('renameProvider'))
end

T.lsp.has_capability['multiple'] = function()
  Clients = {
    { id = 1, name = 'test1', server_capabilities = { renameProvider = true } },
    { id = 2, name = 'test2', server_capabilities = { definitionProvider = true } },
  }
  eq[true](Lsp.has_capability('definitionProvider'))
  eq[true](Lsp.has_capability('renameProvider'))
  eq[false](Lsp.has_capability('codeActionProvider'))
  Clients = {
    { id = 1, name = 'test1', server_capabilities = {} },
    {
      id = 1,
      name = 'testt',
      server_capabilities = { codeActionProvider = { codeActionKinds = { 'quickfix' } } },
    },
  }
  eq[true](Lsp.has_capability('codeActionProvider'))
end

return T
