require("lib.definitions")

local lib = package.user.lib
local dict = lib.dict
local copy = lib.copy

---@alias Options.key string|int
---@alias Options.pattern string|Callable
---@alias Options.patterns (string|Callable)[]

---@class Options : Options.class : instance
---@field data table
---@field include Options.pattern|Options.patterns
---@field exclude Options.pattern|Options.patterns
---@field new nil
---@field __call fun(): table

---@class Options.class : class
---@field new fun(x?: table, include?: Options.pattern|Options.patterns, exclude?: Options.pattern|Options.patterns): Options
local Options = class("Options", nil, {
	static = { "matches" },
})

---@param str string|number
---@param patterns Options.pattern|Options.patterns
---@return boolean
function Options.any_of(str, patterns)
	patterns = as.list(patterns)
	for i = 1, #patterns do
		local pattern = patterns[i]
		local ok = false

		if is.string(pattern) then
			ok = string.match(str, pattern) ~= nil
		elseif is.Callable(pattern) then
			ok = pattern(str)
		end

		if ok then
			return true
		end
	end

	return false
end

---@param str string|number
---@param patterns Options.pattern|Options.patterns
---@return boolean
function Options.all_of(str, patterns)
	patterns = as.list(patterns)
	for i = 1, #patterns do
		local pattern = patterns[i]
		local ok = false

		if is.string(pattern) then
			ok = string.match(str, pattern) ~= nil
		elseif is.Callable(pattern) then
			ok = pattern(str)
		end

		if not ok then
			return false
		end
	end

	return true
end

function Options:initialize(x, include, exclude)
	self.data = x or {}
	self.include = include or {}
	self.exclude = exclude or {}
end

function Options:__call()
	return self.data
end

---@param blank? boolean
---@return Options
function Options:copy(blank)
	if blank then
		return Options:new({}, self.include, self.exclude)
	else
		return Options:new(copy(self.data), self.include, self.exclude)
	end
end

function Options:length()
	return dict.length(self.data)
end

---@param ks Options.key|Options.key[]
---@return boolean
function Options:has(ks)
	return dict.has(self.data, ks)
end

---@param ks Options.key|Options.key[]
---@param value any
---@param force? boolean
---@return Options?
function Options:set(ks, value, force)
	ks = as.list(ks)
	local ks_len = #ks
	value = as.value(value)

	if ks_len == 0 then
		return
	elseif ks_len == 1 then
		if force then
			self.data[ks[1]] = value
		elseif is.na(self.data[ks[1]]) then
			self.data[ks[1]] = value
		end
	elseif dict.set(self.data, ks, value, force) then
		---@type Options
		return self
	end
end

---@param ks Options.key|Options.key[]
---@param value any
---@return Options?
function Options:force_set(ks, value)
	return self:set(ks, value, true)
end

---@param other Options
---@return Options
function Options:lmerge(other)
	for key, value in pairs(other.data) do
		self.data[key] = value
	end
	---@type Options
	return self
end

---@param other Options
---@return Options
function Options:rmerge(other)
	return dict.force_merge(self.data, other.data)
end

Options.merge = Options.lmerge
Options.force_merge = Options.rmerge

---@param ks Options.key|Options.key[]
---@param default? fun(): any
---@return any
function Options:get(ks, default)
	local res = dict.get(self.data, ks, default)
	return as.value(res)
end

---@param ... Options.key|Options.key[]
---@return Options
function Options:select(...)
	---@type Options
	local res = self:copy(true)
	for _, ks in ipairs({ ... }) do
		local value = as.value(self:get(ks))
		if value then
			res:set(ks, value, true)
		end
	end
	return res
end

---@param spec table<Options.key|Options.key[],fun(x: any): any>
---@return Options
function Options:mutate(spec)
	---@type Options
	local res = self:copy()
	for ks, mapper in pairs(spec) do
		local value = mapper(as.value(self:get(ks)))
		res:set(ks, value, true)
	end
	return res
end

---@param ks Options.key|Options.key[]
---@return Options
function Options:without(ks)
	local res = self:copy()
	for _, k in ipairs(as.list(ks)) do
		if self:has(k) then
			res:set(k, nil)
		end
	end
	return res
end

---@param other Options
---@param overwrite? boolean
---@return Options
function Options:union(other, overwrite)
	local res = self:copy()
	for key, value in pairs(other.data) do
		res:set(key, value, overwrite)
	end
	return res
end

---@param other Options
---@return Options
function Options:intersection(other)
	local res = self:copy(true)
	for key, value in pairs(other.data) do
		if self.data[key] then
			res:set(key, value)
		end
	end

	for key, value in pairs(self.data) do
		if other.data[key] then
			res:set(key, value)
		end
	end

	return res
end

---@param fn fun(key: str|int, value: any): any
---@return table<str|int,any>
function Options:map(fn)
	local res = {}
	for key, value in pairs(self.data) do
		res[key] = as.value(fn(key, as.value(value)))
	end
	return Options:new(res, self.include, self.exclude)
end

---@param fn fun(key: str|int, value: any): any
function Options:each(fn)
	for key, value in pairs(self.data) do
		fn(key, as.value(value))
	end
end

---@param fn fun(key: str|int, value: any): boolean
---@return Options
function Options:filter(fn)
	local res = {}
	for key, value in pairs(self.data) do
		value = as.value(value)
		if fn(as.value(value)) then
			res[key] = as.value(fn(key, value))
		end
	end
	return Options:new(res, self.include, self.exclude)
end

---@param filter_fn fun(key: str|int, value: any): boolean
---@param map_fn fun(key: str|int, value: any): any
---@return Options
function Options:filtermap(filter_fn, map_fn)
	local res = self:filter(filter_fn)
	return res:map(map_fn)
end

---@param spec table|Options
---@param opts? is.opts
---@return table?
function Options:match(spec, opts)
	if not is.Options(spec) and not is.pure_table(spec) then
		errorf("spec: Expected pure_table|Options, got [%s] %s", type(spec), spec)
	elseif not is.Options(spec) then
		spec = Options:new(spec)
	end

  return lib.type.match(self.data, spec.data, opts)
end

---@overload fun(x: any, opts?: is.opts): boolean, string?
is.Options = is.Options

local a = Options:new({ a = 1, b = 2, c = 3 })
local b = Options:new({ a = 1, b = -2, d = {} })
local spec = Options:new {
  a = is.int,
  b = is.int,
  c = lib.union("int|function", is.int, is.fun),
  d = lib.union("int|function", is.int, is.fun)
}
b:match(spec)
