require('tests.global')

local T = new_set()
T.integration = new_set()

T.integration['Complex dependency'] = function()
  local C = require('ctxmap')
  C.library.add('tlib', 'ctxmap.lib.builtin')
  C.context.add('a', { b = 'tlib.always() and not tlib.never()' })
  local ctx = C.context.get('a.b()')
  eq[true](ctx())
end

return T
