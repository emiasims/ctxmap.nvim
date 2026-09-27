local M = {}

---@param opts ctxmap.config
function M.setup(opts)
  opts = opts or {}
  if opts.contexts then
    vim.iter(opts.contexts):each(require('ctxmap.context').add)
  end
  if opts.libraries then
    vim.iter(opts.libraries or {}):each(require('ctxmap.library').add)
  end
  if opts.keys then
    vim.iter(opts.keys or {}):each(require('ctxmap.keymap').sets)
  end

  -- all modes except lang
  vim.keymap.set({ '', 't', '!' }, '<Plug>(ctxmap-debug)', '<Cmd>let g:ctxmap_debug = 1<Cr>')
end

-- TODO:
-- dotrepeat / count ?
-- which-key extension

-- text. functions in command mode should return from the command line

-- completion source for blink / cmp

return setmetatable(M, {
  __index = function(_, k)
    if k == 'context' or k == 'library' or k == 'keymap' then
      return require('ctxmap.' .. k)
    end
  end,
})
