-- Add current directory to 'runtimepath' to be able to use 'lua' files
vim.cmd([[let &rtp.=','.getcwd()]])
vim.opt.rtp:prepend('deps/mini.nvim')

if #vim.api.nvim_list_uis() == 0 then
  require('mini.test').setup()

  function RunFiles(str)
    local args = vim.split(str, '.', { plain = true })
    MiniTest.run({
      collect = {
        ---@param case Test-case
        filter_cases = function(case)
          return vim.iter(args):all(function(a)
            return vim.iter(case.desc):any(function(d)
              return d:find(a)
            end)
          end)
        end,
      },
    })
  end
end
