require("lua-utils.type")
local lib = package.user.lib

---@class placeholder.next.result
---@field before? str
---@field next? int
---@field placeholder str
---@field string str

---String matching utilities for template strings
local placeholder = {}

placeholder.example = [[[project]
name = "{name}"
version = "0.0.1"
authors = [
  \{ name="{author}", email="{email}" \}
]
description = "A small example package"
readme = "README.md"
requires-python = ">={version}"
classifiers = [
  "Programming Language :: Python :: 3",
  "Operating System :: OS Independent",
]
license = "{license}"
license-files = ["LICEN[CS]E*"]

[project.urls]
Homepage = "https://github.com/{username}/{name}"
Issues = "https://github.com/{username}/{name}/issues"
]]

---Check if placeholder name is valid
---@param name str|num
function placeholder.validate_placeholder(name)
	if not is.str(name) or not string.match(name, "^[a-zA-Z0-9_.-]+$") then
		errorf("Placeholder `%s` did not match `^[a-zA-Z0-9_.-]+$`", name)
	end
end

---Count consecutive backslashes immediately before byte position `pos`
---@param s string
---@param pos int
---@return int
local function backslashes_before(s, pos)
	local n = 0
	local i = pos - 1
	while i >= 1 and s:sub(i, i) == "\\" do
		n = n + 1
		i = i - 1
	end
	return n
end

---Find the next unescaped `{...}` pair.
---A brace is escaped when preceded by an odd number of backslashes.
---@param s str
---@param start int
---@return int?, int?
function placeholder.find_next_pair(s, start)
	start = start or 1
	local search = start

	while true do
		local opening = s:find("{", search, true)
		if not opening then
			return
		end

		if backslashes_before(s, opening) % 2 == 1 then
			search = opening + 1
		else
			local search_close = opening + 1
			while true do
				local closing = s:find("}", search_close, true)
				if not closing then
					error(sprintf(
						"Could not find closing bracket for opening brace on character %d",
						opening
					))
				end
				if backslashes_before(s, closing) % 2 == 1 then
					search_close = closing + 1
				else
					return opening, closing
				end
			end
		end
	end
end

---Parse one placeholder and return the next state
---@param s string
---@param start int
---@return placeholder.next.result
function placeholder.find_next(s, start)
	start = start or 1
	local open_pos, close_pos = placeholder.find_next_pair(s, start)

	if not open_pos then
		return { string = s:sub(start) }
	end

	local name = s:sub(open_pos + 1, close_pos - 1)
	placeholder.validate_placeholder(name)

	return {
		before = s:sub(start, open_pos - 1),
		placeholder = name:match("^[0-9]+$") and tonumber(name) or name,
		next = close_pos + 1,
		string = s,
	}
end

---Remove one level of backslash escaping from literal template text.
---`\\` -> `\`, `\{` -> `{`, `\}` -> `}`, `\\\{` -> `\{`, ...
---Never apply this to replacement values.
---@param s string
---@return string
function placeholder.unescape(s)
	return (s:gsub("\\(.)", "%1"))
end


---Simple string interpolation with python-like curly braces
---@class template : template.class : instance
---@field string string
---@field placeholders? table<string,any>

---@class template.class : class
---@field new fun(self: template.class, s: str, placeholder?: table<str,str>): template
template = class('template', nil, {
	static = { 'placeholder' }
})
template.placeholder = placeholder
lib.template = template

function template:initialize(s, placeholders)
	self.string = s
	self.placeholders = placeholders or {}
end

---Add a new placeholder definition
---@param name string
---@param replacement string
function template:on(name, replacement)
	self.placeholders[name] = replacement
end

---Parse the string and substitute placeholders with their values
---@return string
function template:parse()
	local placeholders = self.placeholders
	local s = self.string
	local final = {}
	local res = placeholder.find_next(s, 1)

	while res.next do
		final[#final + 1] = placeholder.unescape(res.before)
		local p = res.placeholder
		local replacement = placeholders[p]

		if replacement == nil then
			errorf('%s: Placeholder is undefined', p)
		end

		final[#final + 1] = tostring(replacement)
		res = placeholder.find_next(s, res.next)
	end

	final[#final + 1] = placeholder.unescape(res.string or "")
	return table.concat(final, "")
end

---@param placeholders table<str,str>
function template:define(placeholders)
	for name, repl in pairs(placeholders) do
		self.placeholders[name] = repl
	end
end

-- local t = template:new(placeholder.example)
-- t:define {
-- 	name = "common_utils",
-- 	author = "ABC DEF",
-- 	email = "xyz@gmail.com",
-- 	version = "0.0.1",
-- 	license = "MIT",
-- 	username = "xyz",
-- }
-- print(t:parse())

return lib
