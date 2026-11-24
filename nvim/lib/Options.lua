require("lib.definitions")

local lib = package.user.lib
local dict = lib.dict
local copy = lib.copy

---@alias Options.Map fun(key: Options.Key, value: any): any
---@alias Options.Filter fun(key: Options.Key, value: any): boolean
---@alias Options.Key str|number
---@alias Options.Keys Options.Key|Options.Key[]
---@alias Options.CallablePattern fun(key: Options.Key, value: any): bool
---@alias Options.Pattern Options.Key|Options.CallablePattern
---@alias Options.Patterns Options.Pattern|Options.Pattern[]
---@alias Options.Table table<Options.Key, any>

---@class Options : instance, Options.class
---@field data Options.Table
---@field data_by_group table<Options.Key, Options.Table>
---@field groups table<Options.Key, Options.Patterns>
---@field include Options.Patterns
---@field new nil
---@field __call fun(overrides?: Options.Table): Options.Table

---@class Options.class : class
---@field new fun(self: Options.class, include?: Options.Patterns): Options
local Options = class("Options", nil, {
	static = { "matches", "assert" },
})

---@param key Options.Key
---@param value? any
---@param patterns Options.Patterns
---@return boolean
function Options.matches(key, value, patterns)
	for _, pattern in ipairs(as.list(patterns)) do
		if is.Callable(pattern) then
			if pattern(key, value) then
				return true
			end
		else
			key = as.str(key)
			if string.match(key, pattern) then
				return true
			end
		end
	end

	return false
end

---@param key Options.Key
---@param value? any
---@param patterns Options.Patterns
function Options.assert(key, value, patterns)
	if Options.matches(key, value, patterns) then
		return
	end

	local msg = "%s does not match key `%s` and value `%s`"
	msg = sprintf(msg, patterns, key, value)
	error(msg)
end

---@param name Options.Key
---@param patterns Options.Keys
function Options:add_group(name, patterns)
	self.groups[name] = function(key, value)
		return Options.matches(key, value, patterns)
	end
end

---@param name Options.Key
---@return Options.Table?
function Options:get_group(name)
	return self.data_by_group[name]
end

Options.group = Options.get_group

function Options:set(key, value)
	Options.assert(key, value, self.include)
	value = as.na(value)

	for group, pattern in pairs(self.groups) do
		if Options.matches(key, value, as.list(pattern)) then
			self.data[key] = value
			self.data_by_group[group] = self.data_by_group[group] or {}
			self.data_by_group[group][key] = value
		end
	end
end

---@param include? str|str[]|(fun(key: str, value: any): boolean)
function Options:initialize(include)
	self.include = as.list(include or { ".+" })
	self.groups = { all = { ".+" } }
	self.data = {}
	self.data_by_group = { all = self.data }
end

---@param name str
---@param fn fun(key: Options.Key, value: any): any
---@return Options.Table?
function Options:group_map(name, fn)
	if not self.data_by_group[name] then
		return
	else
		return dict.map(self.data_by_group[name], fn)
	end
end

---@param name str
---@param fn fun(key: Options.Key, value: any): boolean
---@return Options.Table?
function Options:group_filter(name, fn)
	if not self.data_by_group[name] then
		return
	else
		return dict.filter(self.data_by_group[name], fn)
	end
end

---@param fn fun(key: Options.Key, value: any): any
---@return Options.Table?
function Options:map(fn)
	return dict.map(self.data_by_group.all, fn)
end

---@param fn fun(key: Options.Key, value: any): boolean
---@return Options.Table?
function Options:filter(fn)
	return dict.filter(self.data_by_group.all, fn)
end

function Options:merge(tbl)
	for key, value in pairs(tbl) do
		Options.assert(key, value, self.include)
		self:set(key, value)
	end
end

function Options:__call(overrides)
	local res = copy(self.data)
	for key, value in pairs(overrides or {}) do
		Options.assert(key, value, self.include)
		self:set(key, value)
	end
	return res
end

function Options:__add(fn)
	is.Callable(fn, { assert = true, prefix = "fn" })
	return self:map(fn)
end

function Options:__sub(fn)
	is.Callable(fn, { assert = true, prefix = "fn" })
	return self:filter(fn)
end

---@param fn {[1]: str, [2]: Options.Map}
---@return Options.Table
function Options:__mul(fn)
  local res = self:group_map(unpack(fn))
  ---@cast res Options.Table
	return res
end

---@param fn {[1]: str, [2]: Options.Filter}
---@return Options.Table
function Options:__div(fn)
  local res = self:group_filter(unpack(fn))
  ---@cast res Options.Table
  return res
end

-- local opts = Options:new()
-- opts:add_group("something", "[c-z]")
-- opts:set("a", 1)
-- opts:set("b", 10)
-- opts:set("c", 11)
--
-- pp(opts:filter(function(_, x)
-- 	return x > 1
-- end))
--
-- pp(opts / function(_, x)
-- 	return x > 1
-- end)
--

Options.gmap = Options.group_map
Options.gfilter = Options.group_filter
Options.gadd = Options.add_group
lib.Options = Options

return lib
