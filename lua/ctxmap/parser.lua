local EXPR

do
  local lpeg = vim.lpeg
  local C, Cb, Cg, Cmt = lpeg.C, lpeg.Cb, lpeg.Cg, lpeg.Cmt
  local P, R, V = lpeg.P, lpeg.R, lpeg.V
  local locale = lpeg.locale()

  local DIGIT = locale.digit
  local WORD_CHAR = locale.alpha + P('_') + R('\127\255')
  local WS = locale.space ^ 0

  local function sep(...)
    local patt = select(1, ...)
    for _, p in ipairs({ select(2, ...) }) do
      patt = patt * WS * p
    end
    return patt
  end

  EXPR = {

    name = C(WORD_CHAR * (WORD_CHAR + DIGIT) ^ 0),

    -- strings
    str_single = P("'") * (P('\\\\') + "\\'" + (1 - P("'") - '\n')) ^ 0 * "'",
    str_double = P('"') * (P('\\\\') + '\\"' + (1 - P('"') - '\n')) ^ 0 * '"',
    strl_open = '[' * Cg(P('=') ^ 0, 'q') * '[' * P('\n') ^ -1,
    strl_close = ']' * Cg(P('=') ^ 0, 'qe') * ']',
    strl_closeeq = Cmt(V('strl_close') * Cb('q') * Cb('qe'), function(_, _, a, b)
      return a == b
    end),
    str_long = V('strl_open') * Cg((1 - V('strl_closeeq')) ^ 0, 'content') * V('strl_close'),

    string = (V('str_single') + V('str_double') + V('str_long')) / function(str)
      return loadstring('return ' .. str)()
    end,

    index = sep(sep('[', V('string'), ']') + sep('.', V('name')), V('index') ^ -1),
    identifier = sep(V('name'), V('index')^ -1),

    0 * WS * V('identifier') * WS * -1,
  }

  EXPR = P(EXPR)
end

local M = {}

function M.parse(str)
  return EXPR:match(str)
end

return M
