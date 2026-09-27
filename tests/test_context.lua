require('tests.global')
local Context = require('ctxmap.context')
local Builtin = require('ctxmap.lib.builtin')

local T = new_set()
T.context = new_set()
T.context.get = new_set()

T.context.get['non-existent'] = function()
  local fake = Context.get('non_existent_context')
  eq('function', type(fake))
  mt.expect.error(fake, 'Context not found: "non_existent_context"')
end

T.context.get['builtin'] = function()
  eq(Builtin.always, Context.get('always'))
  eq(require('ctxmap.lib.window').left, Context.get('win.left'))
end

T.context.get['string->string'] = function()
  Context.add('test_string1', 'always')
  Context.add('test_string2', 'test_string1')
  eq(Builtin.always, Context.get('test_string2'))

  Context.add('str1', 'str2')
  Context.add('str2', 'str3')
  Context.add('str3', 'always')
  eq(Builtin.always, Context.get('str1'))
end

T.context.get['eval'] = function()
  require('ctxmap.library').add('t', {
    test_func = function(v)
      return v
    end,
  })
  eq[true](Context.get('t.test_func(123) == 123')())
end

T.context.add = new_set()
T.context.add['function'] = function()
  local f = function()
    return true
  end
  Context.add('tf', f)
  eq(f, Context.get('tf'))
end

T.context.add['string'] = function()
  Context.add('test_function', 'always')
  eq(Builtin.always, Context.get('test_function'))
end

T.context.add['overwrite'] = function()
  local test_function1 = function()
    return true
  end
  local test_function2 = function()
    return false
  end
  Context.add('test_overwrite', test_function1)
  Context.add('test_overwrite', test_function2)
  eq(test_function2, Context.get('test_overwrite'))
end

return T
