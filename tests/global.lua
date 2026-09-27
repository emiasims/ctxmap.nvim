_G.mt = require('mini.test')
_G.new_set = mt.new_set
-- _G.eq = mt.expect.equality

local tbl_eq = mt.new_expectation( --
  'table equality',
  vim.deep_equal,
  function(left, right)
    local function diffmsg(path, a, b)
      local path_str = table.concat(path, '.')
      return ('%s:\n  Left:  %s\n  Right: %s'):format(path_str, vim.inspect(a), vim.inspect(b))
    end
    local function _diff(a, b, path)
      if type(a) ~= type(b) then
        return diffmsg(path, a, b)
      end

      if type(a) ~= 'table' then
        return a ~= b and diffmsg(path, a, b) or nil
      end

      local keys = vim.tbl_extend('force', a, b)
      local diffs = {}
      local ix = #path + 1
      for k in pairs(keys) do
        path[ix] = k
        table.insert(diffs, _diff(a[k], b[k], vim.deepcopy(path)))
      end

      return diffs
    end
    return vim.iter(_diff(left, right, {})):flatten(math.huge):join('\n')
  end
)

_G.eq = setmetatable({}, {
  __call = function(_, a, b)
    if type(a) == 'table' and type(b) == 'table' then
      return tbl_eq(a, b)
    end
    return mt.expect.equality(a, b)
  end,
})
eq[true] = function(v)
  mt.expect.equality(true, v and true or false)
end
eq[false] = function(v)
  mt.expect.equality(false, v and true or false)
end

function _G.P(...)
  print('\n')
  print(unpack(vim.iter({ ... }):map(vim.inspect):totable()))
  print('\n')
end
