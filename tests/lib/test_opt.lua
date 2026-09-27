require('tests.global')

local Opt = require('ctxmap.library').get('opt')
local Opt_local = require('ctxmap.library').get('opt_local')
local Opt_global = require('ctxmap.library').get('opt_global')

local T = new_set()
T.opt = new_set()

T.opt.boolean = function()
  vim.opt.wrap = true
  eq[true](Opt.wrap())
  vim.opt.wrap = false
  eq[false](Opt.wrap())
  eq[true](Opt.nowrap())
end

T.opt.numeric = function()
  local winwidth = vim.opt.winwidth:get()
  eq(Opt.winwidth(), winwidth)
  vim.opt.winwidth = winwidth + 10
  eq(Opt.winwidth(), winwidth + 10)
  vim.opt.winwidth = winwidth
end

T.opt.string = function()
  vim.opt.showcmdloc = 'tabline'
  eq(Opt.showcmdloc(), 'tabline')
  vim.opt.showcmdloc = 'statusline'
  eq(Opt.showcmdloc(), 'statusline')
  vim.opt.showcmdloc = 'tabline'
end

T.opt.set = function()
  local fo = Opt.formatoptions
  vim.opt.formatoptions:append('a')
  eq[true](fo().a)
  vim.opt.formatoptions:remove('a')
  eq[false](fo().a)
end

T.opt._local = function()
  vim.opt_global.wrap = false
  vim.opt_local.wrap = true
  eq[true](Opt_local.wrap())
  eq[false](Opt_local.nowrap())
  vim.opt_local.wrap = false
  eq[false](Opt_local.wrap())
  eq[true](Opt_local.nowrap())
end

T.opt._global = function()
  vim.opt_global.wrap = true
  vim.opt_local.wrap = false
  eq[true](Opt_global.wrap())
  eq[false](Opt_global.nowrap())
end

return T
