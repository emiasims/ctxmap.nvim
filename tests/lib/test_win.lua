require('tests.global')
local Win = require('ctxmap.library').get('win')

local T = new_set()

local only = function()
  vim.cmd.only({ mods = { emsg_silent = true } })
end
T.win = new_set({ hooks = { pre_case = only, post_case = only } })

T.win.floating = function()
  eq[false](Win.floating())
  local win = vim.api.nvim_open_win(0, true, {
    relative = 'cursor',
    width = 10,
    height = 10,
    row = 0,
    col = 0,
  })
  eq[true](Win.floating())
  vim.api.nvim_win_close(win, true)
end

T.win.solo = function()
  eq[true](Win.solo())
  local win = vim.api.nvim_open_win(0, true, {
    relative = 'cursor',
    width = 10,
    height = 10,
    row = 0,
    col = 0,
    style = 'minimal',
  })
  eq[false](Win.solo())
  vim.api.nvim_win_close(win, true)
end

T.win.height = function()
  local height = vim.api.nvim_win_get_height(0)
  eq(Win.height(), height)
end

T.win.width = function()
  local width = vim.api.nvim_win_get_width(0)
  eq(Win.width(), width)
end

T.win.left = new_set()

-- these are pretty basic so I won't get complicated with tests
T.win.left['vsplit'] = function()
  eq[true](Win.left())
  vim.cmd.vsplit()
  eq[true](Win.left())
  vim.cmd.wincmd('l')
  eq[false](Win.left())
  vim.cmd.close()
  eq[true](Win.left())
end

T.win.left['split'] = function()
  vim.cmd.split()
  eq[true](Win.left())
  vim.cmd.wincmd('j')
  eq[true](Win.left())
end

T.win.right = new_set()

-- these are pretty basic so I won't get complicated with tests
T.win.right['vsplit'] = function()
  eq[true](Win.right())
  vim.cmd.vsplit()
  eq[false](Win.right())
  vim.cmd.wincmd('l')
  eq[true](Win.right())
  vim.cmd.close()
  eq[true](Win.right())
end

T.win.right['split'] = function()
  vim.cmd.split()
  eq[true](Win.right())
  vim.cmd.wincmd('j')
  eq[true](Win.right())
end

T.win.top = new_set()

T.win.top['split'] = function()
  eq[true](Win.top())
  vim.cmd.split()
  eq[true](Win.top())
  vim.cmd.wincmd('j')
  eq[false](Win.top())
  vim.cmd.close()
  eq[true](Win.top())
end

T.win.top['vsplit'] = function()
  vim.cmd.vsplit()
  eq[true](Win.top())
  vim.cmd.wincmd('l')
  eq[true](Win.top())
  vim.cmd.close()
end

T.win.bottom = new_set()

T.win.bottom['split'] = function()
  eq[true](Win.bottom())
  vim.cmd.split()
  eq[false](Win.bottom())
  vim.cmd.wincmd('j')
  eq[true](Win.bottom())
  vim.cmd.close()
  eq[true](Win.bottom())
end

T.win.bottom['vsplit'] = function()
  vim.cmd.vsplit()
  eq[true](Win.bottom())
  vim.cmd.wincmd('l')
  eq[true](Win.bottom())
  vim.cmd.close()
  eq[true](Win.bottom())
end

return T
