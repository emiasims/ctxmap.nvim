require('tests.global')
local Util = require('ctxmap.util')

local T = new_set()
T.util = new_set()
T.util.resolve = new_set()

local default_opts = {
  ctxmap = { clear = true, count = true, dotrepeat = true },
  keymap = { expr = true, remap = true },
  rule = {},
}

T.util.resolve['basic'] = function()
  local spec = { 'a', { 'always', 'b' } }
  local resolved = Util.keymap.resolve(spec)
  eq(#resolved, 1)
  eq(resolved[1], {
    lhs = 'a',
    opts = default_opts,
    mode = 'n',
    rules = { { rhs = 'b', ctx = 'always', opts = {} } },
  })
end

T.util.resolve['default spec'] = function()
  local spec = { 'a', { 'always', 'b' }, default = 'c' }
  local resolved = Util.keymap.resolve(spec)
  eq(#resolved, 1)
  eq(resolved[1], {
    lhs = 'a',
    opts = default_opts,
    mode = 'n',
    rules = { { rhs = 'b', ctx = 'always', opts = {} } },
    default = { rhs = 'c', opts = {} },
  })
end

T.util.resolve['list spec'] = function()
  local spec = {
    { 'a', { 'always', 'b' }, mode = 'n' },
    { 'x', { 'never', 'y' }, mode = { 'i', 's' } },
  }
  local resolved = Util.keymap.resolve(spec)
  eq(#resolved, 3)
  eq(resolved[1], {
    lhs = 'a',
    opts = default_opts,
    mode = 'n',
    rules = { { rhs = 'b', ctx = 'always', opts = {} } },
  })
  eq(resolved[2], {
    lhs = 'x',
    opts = default_opts,
    mode = 'i',
    rules = { { rhs = 'y', ctx = 'never', opts = {} } },
  })
  eq(resolved[3], {
    lhs = 'x',
    opts = default_opts,
    mode = 's',
    rules = { { rhs = 'y', ctx = 'never', opts = {} } },
  })
end

local function _find_keymap(resolved, lhs, mode)
  return vim.iter(resolved):find(function(km)
    return km.lhs == lhs and km.mode == mode
  end)
end

T.util.resolve['ctx inheritance'] = function()
  local spec = {
    { { 'a', 'b' }, { 'c', 'd' } },
    ctx = 'always',
    mode = { 'n', 'v' },
  }
  local resolved = Util.keymap.resolve(spec)
  eq(#resolved, 4)
  -- don't care about iteration order, using _find_keymap
  eq(_find_keymap(resolved, 'a', 'n'), {
    lhs = 'a',
    opts = default_opts,
    mode = 'n',
    rules = { { rhs = 'b', ctx = 'always', opts = {} } },
  })
  eq(_find_keymap(resolved, 'a', 'v'), {
    lhs = 'a',
    opts = default_opts,
    mode = 'v',
    rules = { { rhs = 'b', ctx = 'always', opts = {} } },
  })
  eq(_find_keymap(resolved, 'c', 'n'), {
    lhs = 'c',
    opts = default_opts,
    mode = 'n',
    rules = { { rhs = 'd', ctx = 'always', opts = {} } },
  })
  eq(_find_keymap(resolved, 'c', 'v'), {
    lhs = 'c',
    opts = default_opts,
    mode = 'v',
    rules = { { rhs = 'd', ctx = 'always', opts = {} } },
  })
end

T.util.resolve['option inheritance'] = function()
  local spec = {
    mode = 'i',
    {
      'c',
      {
        { 'always', 'b' },
        { 'never', 'y', expr = false }, -- Override expr
      },
      expr = true,
      buffer = true,
    },
  }

  local resolved = Util.keymap.resolve(spec)
  eq(#resolved, 1)
  eq(resolved[1], {
    lhs = 'c',
    opts = {
      ctxmap = { clear = true, count = true, dotrepeat = true },
      keymap = { expr = true, remap = true, buffer = true },
      rule = { expr = true, buffer = true },
    },
    mode = 'i',
    rules = {
      { rhs = 'b', ctx = 'always', opts = { expr = true, buffer = true } },
      { rhs = 'y', ctx = 'never', opts = { expr = false, buffer = true } },
    },
  })
end

T.util.resolve['eat'] = function()
  local spec = { 'a', { 'always', { 'b', eat = '%s' } }, mode = 'ia' }
  local resolved = Util.keymap.resolve(spec)
  eq(#resolved, 1)
  eq(resolved[1], {
    lhs = 'a',
    opts = default_opts,
    mode = 'ia',
    rules = { { rhs = 'b', ctx = 'always', opts = {}, eat = '%s' } },
  })
end

return T
