require('tests.global')
local Ts = require('ctxmap.library').get('ts')
local api = vim.api

local function setcursor(line, col)
  api.nvim_win_set_cursor(0, { line, col })
end

local T = new_set({
  hooks = {
    pre_case = function()
      api.nvim_buf_set_lines(0, 0, -1, false, {
        '-- line 1',
        'local x = 1', -- line 2
        'function my_func(arg)', -- line 3
        '  local y = x + arg', -- line 4
        '  print(y)', -- line 5: call expression
        'end', -- line 6
        'my_func(5)', -- line 7: call expression
      })
      vim.bo.filetype = 'lua'
      vim.treesitter.get_parser(0, 'lua'):parse()
    end,
  },
})

T.ts = new_set()

T.ts.filetype = function()
  setcursor(1, 0)
  eq('lua', Ts.filetype())
end

T.ts.is_node = function()
  setcursor(2, 6) -- Cursor on 'x' in `local x = 1`
  eq[true](Ts.is_node('identifier'))

  setcursor(3, 9) -- Cursor on 'my_func' in `function my_func...`
  eq[true](Ts.is_node('identifier'))

  setcursor(5, 2) -- Cursor on 'print' in `print(y)`
  eq[true](Ts.is_node('identifier'))

  setcursor(3, 1) -- Cursor on 'function' keyword
  eq[true](Ts.is_node('function_declaration'))
  eq[false](Ts.is_node('identifier'))
end

T.ts.has_parent = function()
  setcursor(5, 8) -- Cursor on 'y' in `print(y)`
  eq[true](Ts.has_parent('arguments')) -- parent is arguments `(y)`
  eq[false](Ts.has_parent('function_definition'))

  setcursor(3, 17) -- Cursor on 'arg' in `function my_func(arg)`
  eq[true](Ts.has_parent('parameters')) -- parent is parameters `(arg)`
end

T.ts.has_ancestor = function(x)
  setcursor(5, 8) -- Cursor on 'y' in `print(y)`
  eq[true](Ts.has_ancestor('arguments')) -- ancestor is the function block
  eq[true](Ts.has_ancestor('function_call')) -- ancestor is the function block
  eq[true](Ts.has_ancestor('chunk')) -- root node

  setcursor(7, 0) -- Cursor on 'my_func' in call `my_func(5)`
  eq[true](Ts.has_ancestor('chunk'))
  eq[false](Ts.has_ancestor('function_definition')) -- Not inside a function def
end

T.ts.has_child = function()
  setcursor(3, 0) -- Cursor on `function` keyword in `function my_func...`
  eq[true](Ts.has_child('identifier')) -- has child 'my_func'
  eq[true](Ts.has_child('parameters')) -- has child '(arg)'
  eq[true](Ts.has_child('block')) -- has child block with content

  setcursor(5, 2) -- Cursor on `print`
  eq[true](Ts.has_parent('function_call'))
  setcursor(5, 0) -- Move cursor to start of line `print(y)` to select call node itself
  eq[true](Ts.is_node('block'))
  eq[true](Ts.has_parent('function_declaration'))
  eq[true](Ts.has_child('function_call')) -- has child 'print(y)'
  eq[false](Ts.has_child('identifier')) -- 'print' is an identifier of child call
end

T.ts.has_descendant = function()
  setcursor(3, 0) -- Cursor on `function` keyword
  eq[true](Ts.has_descendant('variable_declaration')) -- finds `local y`
  eq[true](Ts.has_descendant('binary_expression')) -- finds `x + arg`
  eq[true](Ts.has_descendant('identifier')) -- finds multiple identifiers `my_func`, `arg`, `y`, `x`, `print`
  eq[false](Ts.has_descendant('chunk')) -- chunk is an ancestor, not descendant
end

T.ts.has_sibling = function()
  setcursor(2, 0) -- Cursor on `local x = 1` line
  eq[true](Ts.has_sibling('function_declaration')) -- sibling is the function def

  setcursor(4, 2) -- Cursor on `local y` line inside function
  eq[true](Ts.has_sibling('function_call')) -- sibling is `print(y)` line
end

T.ts.match_query = function()
  -- Query for any function call identifier
  local call_query = '(function_call) @f'
  setcursor(5, 2) -- Cursor on `print` in `print(y)`
  eq[true](Ts.match_query(call_query))
  setcursor(5, 8) -- Cursor on `y` in `print(y)`
  eq[true](Ts.match_query(call_query))

  setcursor(7, 0) -- Cursor on `my_func` in `my_func(5)`
  eq[true](Ts.match_query(call_query))

  setcursor(4, 8) -- Cursor on `x` in `y = x + arg` (not a call)
  eq[false](Ts.match_query(call_query))

  -- Check using named query (in neovim runtime)
  setcursor(4, 0) -- Cursor on `my_func` in `my_func(5)`
  eq[true](Ts.match_query('folds'))
end

T.ts.match_capture = function()
  -- Query for function call identifier with specific capture name
  local call_query = '(function_call name: (_) @name arguments: (_) @args) @call'

  setcursor(5, 2) -- Cursor on `print` in `print(y)`
  eq[true](Ts.match_capture('name', call_query))
  eq[false](Ts.match_capture('args', call_query))
  eq[true](Ts.match_capture('call', call_query))

  setcursor(7, 8) -- Cursor on `my_func` in `my_func(5)`
  eq[false](Ts.match_capture('name', call_query))
  eq[true](Ts.match_capture('args', call_query))
  eq[true](Ts.match_capture('call', call_query))

  setcursor(4, 8) -- Cursor on `x` (not captured)
  eq[false](Ts.match_capture('call', call_query))

  -- Check using named query (assuming std query exists)
  setcursor(5, 0) -- Cursor on `my_func` in `my_func(5)`
  eq[true](Ts.match_capture('fold', 'folds')) -- Using standard 'function.calls' query
  setcursor(7, 0) -- Cursor on `my_func` in `my_func(5)`
  eq[false](Ts.match_capture('fold', 'folds')) -- Using standard 'function.calls' query
end

return T
