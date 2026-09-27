local Parser = require('ctxmap.parser')
local mt = require('mini.test')
local new_set = mt.new_set
-- local eq = mt.expect.equality

local T = new_set()
T.parser = new_set()
T.parser.parse = new_set()

-- T.parser.parse['basic'] = function()
--   eq[true](Parser.parse('a'))
--   eq[true](Parser.parse('a.b'))
--   eq[false](Parser.parse('a()'))
--   eq[false](Parser.parse('a.b()'))
--   eq[true](Parser.parse('a .b'))
--   eq[true](Parser.parse('a["b"]'))
-- end


return T
