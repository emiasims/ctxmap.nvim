require('tests.global')
local Lines = require('ctxmap.library').get('lines')

local T = new_set()
T.lines = new_set()

local function set_lines_and_cursor(row, col)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    'line one',
    'line two',
    'line three',
    'line four',
    'line five',
  })
  vim.api.nvim_win_set_cursor(0, { row, col })
end

-- lines.before
T.lines.before = new_set()
T.lines.before['basic'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.before('one'))
  eq[false](Lines.before('five'))
end

T.lines.before['with max'] = function()
  set_lines_and_cursor(4, 0) -- '|line four'
  eq[true](Lines.before('three', 1))
  eq[false](Lines.before('one', 1))
  eq[true](Lines.before('one', 3))
end

T.lines.before['edge case start'] = function()
  set_lines_and_cursor(1, 0) -- '|line one'
  eq[false](Lines.before('one'))
end

-- lines.after
T.lines.after = new_set()
T.lines.after['basic'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.after('five'))
  eq[false](Lines.after('one'))
end

T.lines.after['with max'] = function()
  set_lines_and_cursor(2, 0) -- '|line two'
  eq[true](Lines.after('three', 1))
  eq[false](Lines.after('five', 1))
  eq[true](Lines.after('five', 3))
end

T.lines.after['edge case end'] = function()
  set_lines_and_cursor(5, 8) -- 'line fiv|e'
  eq[false](Lines.after('five'))
  eq[true](Lines.after('e'))
end

-- lines.re.before
T.lines.re = new_set()
T.lines.re.before = new_set()
T.lines.re.before['basic'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.re.before('^line one$'))
  eq[false](Lines.re.before('^line five$'))
end

T.lines.re.before['with max'] = function()
  set_lines_and_cursor(4, 0) -- '|line four'
  eq[true](Lines.re.before('three', 1))
  eq[false](Lines.re.before('one', 1))
end

-- lines.re.after
T.lines.re.after = new_set()
T.lines.re.after['basic'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.re.after('^line five$'))
  eq[false](Lines.re.after('^line one$'))
end

T.lines.re.after['with max'] = function()
  set_lines_and_cursor(2, 0) -- '|line two'
  eq[true](Lines.re.after('three', 1))
  eq[false](Lines.re.after('five', 1))
end

-- lines.joined.before
T.lines.joined = new_set()
T.lines.joined.before = new_set()
T.lines.joined.before['basic'] = function()
  set_lines_and_cursor(4, 0) -- '|line four'
  eq[true](Lines.joined.before('two\nline three'))
  eq[true](Lines.joined.before('one\nline two'))
end

T.lines.joined.before['with max'] = function()
  set_lines_and_cursor(5, 0) -- '|line five'
  eq[true](Lines.joined.before('three\nline four', 2))
  eq[false](Lines.joined.before('one\nline two', 2))
end

-- lines.joined.after
T.lines.joined.after = new_set()
T.lines.joined.after['basic'] = function()
  set_lines_and_cursor(2, 0) -- '|line two'
  eq[true](Lines.joined.after('three\nline four'))
  eq[true](Lines.joined.after('four\nline five')) -- Should be 'line three\nline four'
end

T.lines.joined.after['with max'] = function()
  set_lines_and_cursor(1, 0) -- 'line one'
  eq[true](Lines.joined.after('two\nline three', 2))
  eq[false](Lines.joined.after('four\nline five', 2))
end

-- lines.joined.re.before
T.lines.joined.re = new_set()
T.lines.joined.re.before = new_set()
T.lines.joined.re.before['basic'] = function()
  set_lines_and_cursor(4, 0) -- '|line four'
  eq[true](Lines.joined.re.before('two\nline three'))
end

-- lines.joined.re.after
T.lines.joined.re.after = new_set()
T.lines.joined.re.after['basic'] = function()
  set_lines_and_cursor(2, 0) -- '|line two'
  eq[true](Lines.joined.re.after('three\nline four'))
end

-- lines.around
T.lines.around = new_set()
T.lines.around['basic'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.around('two', 'four', 1))
  eq[false](Lines.around('one', 'five', 1))
  eq[true](Lines.around('one', 'five', 2))
end

T.lines.around['separate max'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.around('two', 'four', 1, 1))
  eq[false](Lines.around('one', 'five', 1, 1))
  eq[true](Lines.around('one', 'five', 2, 2))
  eq[true](Lines.around('two', 'five', 1, 2))
  eq[false](Lines.around('one', 'four', 1, 1))
end

-- lines.re.around
T.lines.re.around = new_set()
T.lines.re.around['basic'] = function()
  set_lines_and_cursor(3, 5) -- 'line |three'
  eq[true](Lines.re.around('^line two$', '^line four$', 1))
  eq[false](Lines.re.around('^line one$', '^line five$', 1))
end

-- lines.joined.around
T.lines.joined.around = new_set()
T.lines.joined.around['basic'] = function()
  set_lines_and_cursor(3, 0) -- '|line three'
  eq[true](Lines.joined.around('one\nline two', 'four\nline five', 2))
  eq[false](Lines.joined.around('one\nline two', 'four\nline five', 1))
end

-- lines.joined.re.around
T.lines.joined.re.around = new_set()
T.lines.joined.re.around['basic'] = function()
  set_lines_and_cursor(3, 0) -- '|line three'
  eq[true](Lines.joined.re.around('one\nline two', 'four\nline five', 2))
  eq[false](Lines.joined.re.around('one\nline two', 'four\nline five', 1))
end

return T
