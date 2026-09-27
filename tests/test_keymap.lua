local Keymap = require('ctxmap.keymap')
require('tests.global')

local function keymap_evals_to(lhs, expected, mode)
  local res = require('ctxmap.util').keymap.evals_to(lhs, mode)
  if type(expected) == 'string' and type(res) == 'string' then
    expected = vim.fn.keytrans(vim.keycode(expected))
    res = vim.fn.keytrans(vim.keycode(res))
  end
  eq(res, expected)
end

local T = new_set()
T.keymap = new_set()
T.keymap.set = new_set()
T.keymap.opts = new_set()

T.keymap.set['basic'] = function()
  Keymap.set('n', 'a', { 'always', 'b' })
  keymap_evals_to('a', 'b')
end

T.keymap.set['multiple rules'] = function()
  Keymap.set('n', 'a', {
    { 'always', 'b' },
    { 'never', 'c' },
  })
  keymap_evals_to('a', 'b')

  -- Swap contexts
  Keymap.set('n', 'a', {
    { 'never', 'b' },
    { 'always', 'c' },
  })
  keymap_evals_to('a', 'c')
end

T.keymap.set['defaults'] = function()
  Keymap.set('n', 'a', { 'never', 'b' })
  keymap_evals_to('a', 'a')

  Keymap.set('n', 'a', { 'never', 'b' }, { default = 'c' })
  keymap_evals_to('a', 'c')
end

T.keymap.set['override existing'] = function()
  Keymap.set('n', 'a', { 'always', 'b' })
  Keymap.set('n', 'a', { 'always', 'c' })
  keymap_evals_to('a', 'c')
end

T.keymap.add = new_set()

T.keymap.add['basic'] = function()
  Keymap.set('n', 'a', { 'never', 'b' })
  Keymap.add('n', 'a', { 'always', 'c' })
  keymap_evals_to('a', 'c')
end

T.keymap.add['add to non-existent'] = function()
  Keymap.add('n', 'x', { 'always', 'y' })
  keymap_evals_to('x', 'y')
end

T.keymap.add['add multiple rules'] = function()
  Keymap.set('n', 'z', { 'never', '1' })
  Keymap.add('n', 'z', { 'never', '2' })
  Keymap.add('n', 'z', { 'always', '3' })
  keymap_evals_to('z', '3')
end

T.keymap.sets = new_set()

T.keymap.sets['clear'] = function()
  Keymap.sets({
    { 'a', { 'never', 'b' } },
    { 'a', { 'always', 'c' }, clear = false },
  })
  keymap_evals_to('a', 'c')
end

return T
