local Unloaded = {}
local Library = require('ctxmap.lib.builtin')

local M = {}

local function load(name)
  if Unloaded[name] then
    Library[name] = require(Unloaded[name])
    Unloaded[name] = nil
  end
end

function M.lookup(str)
  if str:find('^[_%w. ]+$') then
    local spec = vim.split(str:gsub(' ', ''), '.', { plain = true })
    load(spec[1])
    return vim.tbl_get(Library, unpack(spec))
  end
  return M.get(str)
end

function M.get(str)
  load(str)
  return Library[str]
end

function M.browse()
  for k in pairs(Unloaded) do
    load(k)
  end
  return Library
end

function M.add(name, mod)
  vim.validate('name', name, 'string')
  vim.validate('modname', mod, { 'string', 'table' })
  if type(mod) == 'string' and not package.loaded[mod] then
    Unloaded[name] = mod
  elseif type(mod) == 'string' and package.loaded[mod] then
    Library[name] = package.loaded[mod]
  else
    Library[name] = mod
  end
end

vim
    .iter({
      ts = 'ctxmap.lib.treesitter',
      lsp = 'ctxmap.lib.lsp',
      text = 'ctxmap.lib.text',
      lines = 'ctxmap.lib.lines',
      cmd = 'ctxmap.lib.cmdline',
      win = 'ctxmap.lib.window',
    })
    :each(M.add)

return M
