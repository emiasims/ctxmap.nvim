return {
  left = function()
    return vim.fn.winnr() == vim.fn.winnr('h')
  end,
  right = function()
    return vim.fn.winnr() == vim.fn.winnr('l')
  end,
  top = function()
    return vim.fn.winnr() == vim.fn.winnr('k')
  end,
  bottom = function()
    return vim.fn.winnr() == vim.fn.winnr('j')
  end,

  solo = function()
    return #vim.api.nvim_tabpage_list_wins(0) == 1
  end,
  floating = function()
    return vim.api.nvim_win_get_config(0).relative ~= ''
  end,
  height = function()
    return vim.api.nvim_win_get_height(0)
  end,
  width = function()
    return vim.api.nvim_win_get_width(0)
  end,
}
