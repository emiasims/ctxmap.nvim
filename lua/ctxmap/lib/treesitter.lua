local M = {}
local ts = vim.treesitter

--- Get the Treesitter filetype at the cursor position.
--- Falls back to vim.bo.filetype if Treesitter parser is unavailable.
---@return string
function M.filetype()
  local success, parser = pcall(ts.get_parser)
  if success then
    local r, c = unpack(vim.api.nvim_win_get_cursor(0))
    r = r - 1
    ---@diagnostic disable-next-line: need-check-nil
    return parser:language_for_range({ r, c, r, c }):lang()
  end
  return vim.bo.filetype
end

local _check = vim.func._memoize(1, function(name)
  return function(node)
    return node and node:type() == name
  end
end)

--- Check if the node at the cursor has a specific type.
---@param name string The node type name.
---@return boolean
function M.is_node(name)
  return _check(name)(ts.get_node())
end

--- Check if the parent of the node at the cursor has a specific type.
---@param name string The node type name.
---@return boolean
function M.has_parent(name)
  return _check(name)(ts.get_node():parent())
end

--- Check if any ancestor of the node at the cursor has a specific type.
---@param name string The node type name.
---@return boolean?
function M.has_ancestor(name)
  local node = ts.get_node():parent()
  while node and not _check(name)(node) do
    node = node:parent()
  end
  return _check(name)(node)
end

--- Check if any direct child of the node at the cursor has a specific type.
---@param name string The node type name.
---@return boolean?
function M.has_child(name)
  local node = ts.get_node()
  return node and vim.iter(node:iter_children()):any(_check(name))
end

--- Check if any sibling of the node at the cursor has a specific type.
--- Siblings are children of the same parent node.
---@param name string The node type name.
---@return boolean?
function M.has_sibling(name)
  local node = ts.get_node():parent()
  return node and vim.iter(node:iter_children()):any(_check(name))
end

--- Check if any descendant of the node at the cursor has a specific type.
--- Traverses the subtree rooted at the current node's children.
---@param name string The node type name.
---@return boolean?
function M.has_descendant(name)
  local node = ts.get_node()
  local function traverse(n)
    return n and (n:type() == name or vim.iter(n:iter_children()):any(traverse))
  end
  return node and vim.iter(node:iter_children()):any(traverse)
end

local function _lookup_query(query)
  -- want this to error if query not found
  if vim.startswith(query, '(') then
    return ts.query.parse(M.filetype(), query)
  end
  return ts.query.get(M.filetype(), query)
end

--- Check if the node at the cursor matches a Treesitter query.
--- The query can be a predefined query name or a raw S-expression string.
---@param query_str string The query name or S-expression.
---@return boolean
function M.match_query(query_str)
  local pos = vim.api.nvim_win_get_cursor(0)
  pos = { pos[1] - 1, pos[2], pos[1] - 1, pos[2] + 1 }
  local query = _lookup_query(query_str)
  local root = ts.get_parser():parse()[1]:root()
  return vim.iter(query:iter_captures(root, 0, pos[1], pos[3] + 1)):any(function(_, capture)
    return ts.node_contains(capture, pos)
  end)
end

--- Check if the node at the cursor matches a specific capture in a Treesitter query.
-- Asserts if the capture name is not found in the query.
---@param capture_name string The name of the capture (e.g., "@function.inner").
---@param query_str string The query name or S-expression containing the capture.
---@return boolean
function M.match_capture(capture_name, query_str)
  local query = _lookup_query(query_str)
  assert(
    vim.tbl_contains(query.captures, capture_name),
    ('Capture name "%s" not found in query "%s"'):format(capture_name, query_str)
  )

  local pos = vim.api.nvim_win_get_cursor(0)
  pos = { pos[1] - 1, pos[2], pos[1] - 1, pos[2] + 1 }

  local root = ts.get_parser():parse()[1]:root()

  return vim.iter(query:iter_captures(root, 0, pos[1], pos[3] + 1)):any(function(id, capture)
    return query.captures[id] == capture_name and ts.node_contains(capture, pos)
  end)
end

return M
