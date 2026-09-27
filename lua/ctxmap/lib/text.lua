local M = { re = {} }

local function _get_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local text = vim.api.nvim_get_current_line()
  return text:sub(1, col), text:sub(col + 1)
end

function M.eol()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local cols = #vim.api.nvim_get_current_line()
  return col >= cols
end

function M.sol()
  return vim.api.nvim_win_get_cursor(0)[2] == 0
end

function M.line(pat, delim)
  local before, after = _get_line()
  if pat:find('%%#') then
    delim = delim and vim.pesc(delim) or '\3\2'
    return (before .. delim .. after):find(pat:gsub('%%#', delim))
  end
  return (before .. after):find(pat)
end

-- TODO mode cmdline?
function M.before(pat)
  if pat:sub(#pat) ~= '$' then
    pat = pat .. '$'
  end
  local text = _get_line()
  return text:find(pat)
end

function M.after(pat)
  if pat:sub(1, 1) ~= '^' then
    pat = '^' .. pat
  end
  local _, text = _get_line()
  return text:find(pat)
end

function M.around(pat_before, pat_after)
  local before, after = _get_line()
  return before:find(pat_before) and after:find(pat_after)
end

function M.re.before(regex)
  local text = _get_line()
  return require('ctxmap.util').compiled_vim_regexes[regex]:match_str(text)
end

function M.re.after(regex)
  local _, text = _get_line()
  return require('ctxmap.util').compiled_vim_regexes[regex]:match_str(text)
end

function M.re.around(regex_before, regex_after)
  return M.re.before(regex_before) and M.re.after(regex_after)
end

return M
