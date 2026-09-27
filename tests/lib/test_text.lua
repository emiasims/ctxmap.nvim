require('tests.global')
local Text = require('ctxmap.library').get('text')

local T = new_set()
T.text = new_set()

local function set_line_and_cursor(line, col)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
  vim.api.nvim_win_set_cursor(0, { 1, col })
end

T.text.before = new_set()

T.text.before['basic'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.before('hello'))
  eq[false](Text.before('abc'))
  eq[true](Text.before(''))
end

T.text.before['multiline'] = function()
  set_line_and_cursor('hello\\nworld', 7)
  eq[false](Text.before('world'))
end

T.text.before['anchored'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.before('^hello'))
  eq[false](Text.before('^ world'))
  set_line_and_cursor('hello world', 0)
  eq[false](Text.before('^hello'))
  eq[true](Text.after('^hello'))
end

T.text.after = new_set()

T.text.after['basic'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.after('world'))
  eq[false](Text.after('abc'))
  eq[true](Text.after(''))
end

T.text.after['multiline'] = function()
  set_line_and_cursor('hello\\nworld', 1)
  eq[false](Text.after('hello'))
end

T.text.around = new_set()

T.text.around['basic'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.around('hello', 'world'))
  eq[false](Text.around('hello', 'abc'))
  eq[false](Text.around('abc', 'world'))
end

T.text.after['anchored'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.after('world$'))
  eq[false](Text.after('hello$'))
  set_line_and_cursor('hello world', 11)
  eq[false](Text.after('world$'))
  eq[false](Text.after('world$'))
end

T.text.re = new_set()

T.text.re.before = new_set()

T.text.re.before['basic'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.re.before('hello'))
  eq[false](Text.re.before('abc'))
end

T.text.re.before['multiline'] = function()
  set_line_and_cursor('hello\\nworld', 7)
  eq[false](Text.re.before('world'))
end

T.text.re.after = new_set()

T.text.re.after['basic'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.re.after('world'))
  eq[false](Text.re.after('abc'))
end

T.text.re.after['multiline'] = function()
  set_line_and_cursor('hello\\nworld', 2)
  eq[false](Text.re.after('hello$'))
end

T.text.re.before['anchored'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.re.before('^hello'))
  eq[false](Text.re.before('^world'))
  set_line_and_cursor('hello world', 0)
  eq[false](Text.re.before('^hello'))
  eq[true](Text.re.after('^hello'))
end

T.text.re.around = new_set()

T.text.re.around['basic'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.re.around('hello', 'world'))
  eq[false](Text.re.around('hello', 'abc'))
  eq[false](Text.re.around('abc', 'world'))
  eq[false](Text.re.around('abc', 'def'))
end

T.text.re.after['anchored'] = function()
  set_line_and_cursor('hello world', 5)
  eq[true](Text.re.after('world$'))
  eq[false](Text.re.after(' hello$'))
  set_line_and_cursor('hello world', 11)
  eq[true](Text.re.before('worl$'))
  eq[true](Text.re.before('^h'))
end

return T
