require 'lua-utils.string'
local dict = require 'lua-utils.dict'

---String matching utilities for template strings
local placeholder = {}
-- local pyproject_toml = [[[project]
-- name = "{name}"
-- version = "0.0.1"
-- authors = [
--   \\{ name="{author}", email="{email}" \\},
-- ]
-- description = "A small example package"
-- readme = "README.md"
-- requires-python = ">={version}"
-- classifiers = [
--   "Programming Language :: Python :: 3",
--   "Operating System :: OS Independent",
-- ]
-- license = "{license}"
-- license-files = ["LICEN[CS]E*"]
--
-- [project.urls]
-- Homepage = "https://github.com/{username}/{name}"
-- Issues = "https://github.com/{username}/{name}/issues"
-- ]]


---Check if placeholder name is valid
---@param name string | number
---@return boolean?
function placeholder.check_name(name)
  if type(name) == 'string' and not string.match(name, '^[a-zA-Z0-9_.-]+$') then
    errorf('Placeholder `%s` did not match `^[a-zA-Z0-9_.-]+$`', name)
  else
    return true
  end
end

function placeholder.find_next_pair(s, start)
  start = start or 1
  local opening = string.find(s, '{', start, true)

  if not opening then
    return
  end

  local till_opening = string.sub(s, start, opening - 1)
  local _, escaped = till_opening:gsub('\\+$', '')

  if not (escaped == 0 or escaped % 2 == 0) then
    return placeholder.find_next_pair(s, opening + 1)
  end

  local closing = s:find('\\*[}]', opening + 1)
  if not closing then
    error(sprintf("Could not find closing bracket for opening parenthesis on character %d", opening))
  end

  _, escaped = till_opening:gsub('\\+$', '')
  if not (escaped == 0 or escaped % 2 == 0) then
    return placeholder.find_next_pair(s, till_opening + 1)
  end

  return opening, closing
end

placeholder.next_pair = placeholder.find_next_pair

---Parse one placeholder and return the next state
---@param s string
---@return placeholder.next.result?
function placeholder.find_next(s, start)
  start = start or 1
  local open_pos, close_pos = placeholder.next_pair(s, start)

  if not open_pos then
    return {
      string = s,
      next = false
    }
  end

  local name = s:sub(open_pos + 1, close_pos - 1)
  placeholder.check_name(name)
  local before = s:sub(start, open_pos - 1)
  local result = {}

  result.before = before

  if name:match('^[0-9]+$') then
    result.placeholder = tonumber(name)
  else
    result.placeholder = name
  end

  result.before = before
  result.next = close_pos + 1
  result.string = s

  return result
end

placeholder.next = placeholder.find_next

---Simple string interpolation with python-like curly braces
---@class template
---@field string string
---@field placeholders? table<string,any>
---@field utils table<string,function>
---@overload fun(s: string, placeholders?: table)
local template = class 'template'
template.placeholder = placeholder

function template:initialize(s, placeholders)
  self.string = s
  self.placeholders = placeholders or {}
end

---Add a new placeholder definition
---@param name string
---@param replacement string
function template:add_placeholder(name, replacement)
  self.placeholders[name] = replacement
end

---Add new placeholders in a dict
---@param placeholders table<string,any>
function template:add_placeholders(placeholders)
  dict.force_merge(self.placeholders, placeholders)
end

---Add new placeholder(s)
---@overload fun(name: string, replacement: string)
---@overload fun(placeholders: table<string,any>)
function template:P(...)
  local args = { ... }
  if #args == 2 then
    self:add_placeholder(unpack(args))
  else
    validate.placeholders(args[1], 'table')
    self:add_placeholders(args[1])
  end
end

---Parse the string and substitute placeholders with their values
---@return string
function template:parse()
  placeholders = placeholders or {}
  placeholders = dict.merge(placeholders, self.placeholders)
  local s = self.string
  local res = placeholder.next(s, 1)

  if not res.next then
    return res.string
  end

  local final = {}
  local final_l = 0
  local push = function(x)
    final[final_l + 1] = x
    final_l = final_l + 1
  end

  while res.next do
    local before = res.before
    local p = res.placeholder
    local replacement = placeholders[p]

    if replacement == nil then
      errorf('%s: Placeholder is undefined', p)
    end

    push(before)
    push(replacement)

    res = placeholder.next(s, res.next)
  end

  return table.concat(final, "")
end

return placeholder
