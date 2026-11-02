require("lua-utils.definitions")
require("lua-utils.type")

local lib = package.user.lib
local as = lib.as
local is = lib.is

---@class Set

---@overload fun(tbl: table): Set
local Set = {}
local Setmt = { type = "Set" }
setmetatable(Set, Set)

---@param x Set
---@param sort? boolean|fun(a: any, b: any): boolean
---@return any[]
function Set.as_list(x, sort)
	local res = {}
	for value, _ in pairs(x) do
		res[#res + 1] = value
	end

	if sort then
		if type(sort) == "function" then
			table.sort(res, sort)
		else
			table.sort(res)
		end
	end

	return res
end

---@param x Set
---@return integer
function Set.length(x)
	local len = 0
	for _, _ in pairs(x) do
		len = len + 1
	end
	return len
end

---@param x Set
---return boolean
function Set.is_empty(x)
	return Set.length(x) == 0
end

---@param x Set
---@return boolean
function Set.not_empty(x)
	return not Set.is_empty(x)
end

---@param x Set
---@param y Set
---@return boolean
function Set.has_same_length(x, y)
	return Set.length(x) == Set.length(y)
end

---@param x Set
---@param y Set
---@return boolean
function Set.equals(x, y)
	if Set.length(x) ~= Set.length(y) then
		return false
	end

	for value, _ in pairs(y) do
		if not x[value] then
			return false
		end
	end

	return true
end

---@param x Set
---@param y Set
---@return boolean
function Set.not_equals(x, y)
	if Set.length(x) ~= Set.length(y) then
		return true
	end

	for value, _ in pairs(y) do
		if x[value] then
			return false
		end
	end

	return true
end

---Is x a subset of y
---@param x Set
---@param y Set
---@param strict? boolean
---@return boolean
function Set.is_subset(x, y, strict)
	if not strict then
		if Set.length(x) > Set.length(y) then
			return false
		end
	else
		if Set.length(x) >= Set.length(y) then
			return false
		end
	end

	for value, _ in pairs(x) do
		if not y[value] then
			return false
		end
	end

	return true
end

---Is x a superset of y
---@param x Set
---@param y Set
---@param strict? boolean
---@return boolean
function Set.is_superset(x, y, strict)
	return Set.is_subset(y, x, strict)
end

---@param x Set
---@param y Set
---@return Set
function Set.intersection(x, y)
	local res = Set.new({})
	for value, _ in pairs(x) do
		if y[value] then
			res[value] = true
		end
	end
	for value, _ in pairs(y) do
		if x[value] then
			res[value] = true
		end
	end
	return res
end

---@param x Set
---@param y Set
---@return Set
function Set.union(x, y)
	local res = Set.new({})
	for value, _ in pairs(x) do
		res[value] = true
	end
	for value, _ in pairs(y) do
		res[value] = true
	end
	return res
end

---@param x Set
---@param y Set
---@return Set
function Set.difference(x, y)
	local res = Set.new({})
	for value, _ in pairs(x) do
		res[value] = true
	end
	for value, _ in pairs(y) do
		res[value] = nil
	end
	return res
end

---@param x Set
---@param f fun(elem: any): any
---@param safe? boolean
---@return Set
function Set.map(x, f, safe)
	local res = Set.new({})
	for value, _ in pairs(x) do
		if safe then
			local ok
			value = as.value(value)
			ok, value = pcall(f, value)
			if ok then
				res[value] = true
			end
		else
			res[value] = f(value)
		end
	end
	return res
end

---@param x Set
---@param f string|string[]|fun(elem: any): any
---@param safe? boolean
---@return Set
function Set.filter(x, f, safe)
	if type(f) == "string" or (type(f) == "table" and type(f[1]) == "string") then
		return Set.grep(x, f)
	end

	local res = Set.new({})
	for value, _ in pairs(x) do
		if safe then
			value = as.value(value)
			local ok, check = pcall(f, value)
			if ok and check then
				res[value] = true
			end
		elseif f(value) then
			res[value] = value
		end
	end
	return res
end

---@param x Set
---@param elems any
---@return boolean[]
function Set.has(x, elems)
	local res = {}
	for _, check_value in ipairs(elems) do
		local ind = #res + 1
		res[ind] = true
		if not x[check_value] then
			res[ind] = false
		end
	end
	return res
end

---@param x Set
---@param patterns string|string[]
---@return any[]
function Set.grep(x, patterns)
	local res = {}
	patterns = as.list(patterns)

	for value, _ in pairs(x) do
		value = tostring(value)
		for _, pattern in ipairs(patterns) do
			if string.match(value, pattern) then
				local ind = #res + 1
				res[ind] = value
				break
			end
		end
	end
	return res
end

---@param x Set
---@param fn? fun(a: any, b: any): boolean
---@return any[]
function Set.sort(x, fn)
	if fn then
		table.sort(x, function(a, b)
			a = as.value(a)
			b = as.value(b)
			return fn(a, b)
		end)
	else
		table.sort(x)
	end
	return x
end

Setmt.__call = Set.as_list
Setmt.__add = Set.union
Setmt.__sub = Set.difference
Setmt.__le = Set.is_subset
Setmt.__mod = Set.grep
Setmt.__div = Set.filter
Setmt.__pow = Set.intersection
Setmt.__lt = function(x, y)
	return Set.is_subset(x, y, true)
end

---@param tbl? any[]
---@return Set
function Set.new(tbl)
	local new = setmetatable({}, Setmt)

	if tbl then
		for _, value in pairs(tbl) do
			new[value] = true
		end
	end

	return new
end

is.Set = lib.defguard("Set", function(x)
	if not is.table(x) then
		return "Expected Set"
	end

	local mt = getmetatable(x)
	if not mt or mt.type ~= "Set" then
		return "Expected Set"
	end
end)

---@param tbl table
---@return Set
function Set:__call(tbl)
	return Set.new(tbl)
end

package.user.lib.Set = Set
