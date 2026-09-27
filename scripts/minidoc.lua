-- Input: all '.lua' files from 'lua/' directory
local input = {}
for _, f in ipairs(vim.fn.glob('lua/**/*.lua', true, true)) do
  table.insert(input, f)
end

-- Output: 'doc/ctxmap.txt'
local output = 'doc/ctxmap.txt'

-- Generate documentation
require('mini.doc').generate(input, output)
