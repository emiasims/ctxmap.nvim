local Line
Line = {
  iterator = function(forward, max)
    local line, c = unpack(vim.api.nvim_win_get_cursor(0))
    line = line - 1

    local tnext = vim.api.nvim_get_current_line()
    tnext = forward and tnext:sub(c + 1) or tnext:sub(1, c)

    return vim
      .iter(function()
        local text = tnext
        line = line + (forward and 1 or -1)
        tnext = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1]
        return text
      end)
      :take(max and max + 1 or math.huge)
  end,

  accumulator = function(forward, max)
    local accumulation
    return vim.iter(Line.iterator(forward, max)):map(function(line)
      if not accumulation then
        accumulation = line
      elseif forward then
        accumulation = accumulation .. '\n' .. line
      else
        accumulation = line .. '\n' .. accumulation
      end
      return accumulation
    end)
  end,
}

local Match = {
  lua = function(pat)
    return function(line)
      return line:find(pat)
    end
  end,
  vim = function(regex)
    local re = require('ctxmap.util').compiled_vim_regexes[regex]
    return function(line)
      return re:match_str(line)
    end
  end,
}

local function build(forward, get_it, matching)
  return function(pat, max)
    local lit = get_it(forward, max)
    return lit:any(matching(pat))
  end
end

local M = {
  before = build(false, Line.iterator, Match.lua),
  after = build(true, Line.iterator, Match.lua),
  re = {
    before = build(false, Line.iterator, Match.vim),
    after = build(true, Line.iterator, Match.vim),
  },
  joined = {
    before = build(false, Line.accumulator, Match.lua),
    after = build(true, Line.accumulator, Match.lua),
    re = {
      before = build(false, Line.accumulator, Match.vim),
      after = build(true, Line.accumulator, Match.vim),
    },
  },
}

function M.surround(max, delim)
  delim = delim and vim.pesc(delim) or '\3\2'
  return function(pat)
    local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
    local start = math.max(0, lnum - max - 1)
    local lines = vim.api.nvim_buf_get_lines(0, start, lnum + max, false)
    if pat:find('%%#') then
      local ix = math.ceil(#lines / 2)
      lines[ix] = lines[ix]:sub(1, col) .. delim .. lines[ix]:sub(col + 1)
      pat = pat:gsub('%%#', delim)
    end
    return table.concat(lines, '\n'):find(pat)
  end
end

---@param pat_before string
---@param pat_after string
---@param max number
---@return boolean
---@overload fun(pat_before: string, pat_after: string, max_before: number, max_after: number): boolean
function M.around(pat_before, pat_after, max, max_after)
  return M.before(pat_before, max) and M.after(pat_after, max_after or max)
end

---@param regex_before string
---@param regex_after string
---@param max number
---@return boolean
---@overload fun(regex_before: string, regex_after: string, max_before: number, max_after: number): boolean
function M.re.around(regex_before, regex_after, max, max_after)
  return M.re.before(regex_before, max) and M.re.after(regex_after, max_after or max)
end

---@param pat_before string
---@param pat_after string
---@param max number
---@return boolean
---@overload fun(pat_before: string, pat_after: string, max_before: number, max_after: number): boolean
function M.joined.around(pat_before, pat_after, max, max_after)
  return M.joined.before(pat_before, max) and M.joined.after(pat_after, max_after or max)
end

---@param regex_before string
---@param regex_after string
---@param max number
---@return boolean
---@overload fun(regex_before: string, regex_after: string, max_before: number, max_after: number): boolean
function M.joined.re.around(regex_before, regex_after, max, max_after)
  return M.joined.re.before(regex_before, max) and M.joined.re.after(regex_after, max_after or max)
end

return M
