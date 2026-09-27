local M = {}
M.level = vim.log.levels.ERROR

---@param level vim.log.levels
function M.set_level(level)
  level = type(level) == 'string' and vim.log.levels[level:upper()] or level
  assert(level <= 5 and level >= 0, 'Invalid log level')
  M.level = level
end

local function logger(name, level, once)
  local notify = once and vim.notify_once or vim.notify
  return function(msg, ...)
    if M.level > level then
      return
    end
    local args = { ... }
    for i = 1, #args do
      if type(args[i]) == 'function' then
        args[i] = args[i]()
      elseif type(args[i]) == 'table' then
        args[i] = vim.inspect(args[i])
      end
    end
    notify('ctxmap: ' .. msg:format(unpack(args)), level)
  end
end

for name, level in pairs(vim.log.levels) do
  if level < vim.log.levels.OFF then
    name = name:lower()
    M[name] = logger(name, level, false)
    M[name .. '_once'] = logger(name, level, true)
  end
end

return M
