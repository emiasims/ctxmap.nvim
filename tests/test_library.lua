require('tests.global')
local Library = require('ctxmap.library')

local T = new_set()
T.library = new_set()
T.library.add = new_set()

T.library.add['string module'] = function()
  Library.add('test_lib', 'ctxmap.lib.builtin')
  eq(Library.get('always'), Library.lookup('test_lib.always'))
end

T.library.add['table module'] = function()
  local t = {
    test_func = function()
      return true
    end,
  }
  Library.add('t', t)
  eq(t.test_func, Library.lookup('t.test_func'))
end

return T
