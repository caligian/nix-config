require("lua-utils.list")

local lib = package.user.lib
local list = lib.list
local copy = lib.copy
local NIL = lib.NIL

---@class KeyError.class : Error.class : class
---@field new fun(self: KeyError.class, key: str, metadata: table): KeyError
KeyError = class("KeyError", Error)
package.user.lib.KeyError = KeyError

---@class KeyError : KeyError.class : instance
---@field key any
---@field metadata table
---@overload fun(key: any, metadata?: table)

function KeyError:__call()
	errorf("Nonexistent key: %s\nmetadata: %s", self.key, self.metadata)
end

function KeyError:initialize(key, metadata)
	Error.initialize(self, "KeyError", key, metadata or {})
	self.key = key
end

---@overload fun(x: any, opts?: is.opts): boolean, string?
is.KeyError = is.KeyError

--- Dictionary utilities
local dict = {}

function dict.copy(x, deep)
	return copy(x, deep)
end

---Get dict keys
---@param x table
---@return table
function dict.keys(x)
	local ks = {}
	for key, _ in pairs(x) do
		ks[#ks + 1] = key
	end
	return ks
end

---Get dict values
---@param x table
---@return table
function dict.values(x)
	local vs = {}
	local i = 0

	for _, value in pairs(x) do
		i = i + 1
		vs[i] = value
	end

	return vs
end

---Get dict size
---@param x table
---@return number
function dict.length(x)
	local n = 0
	for _ in pairs(x) do
		n = n + 1
	end
	return n
end

---Is dict empty?
---@param x table
---@return boolean
function dict.is_empty(x)
	for _ in pairs(x) do
		return false
	end
	return true
end

---@class dict.set.opts
---@field force? boolean
---@field raise? boolean
---@field throw? boolean

---Set or force set value at keys
---@param x table
---@param ks table
---@param value any
---@param opts? dict.set.opts|boolean
---@return table?|KeyError
function dict.set(x, ks, value, opts)
	opts = opts or {}
  opts = is.boolean(opts) and {force = opts} or opts
  local force = opts.force
	local level1 = x
	value = as.value(value)

	if type(ks) ~= "table" then
		ks = { ks }
	end

	for i = 1, #ks - 1 do
		local k = ks[i]
		local v = x[k]

		if type(v) == "table" then
			x = v
		elseif not force then
			local err = KeyError:new(k, { path = ks, level = x })
			if opts.raise or opts.throw then
				err()
			else
				return err
			end
		else
			x[k] = {}
			x = x[k]
		end
	end

	x[ks[#ks]] = value
	return level1
end

---Force set value at keys and create tables if necessary
---@param x table
---@param ks table
---@param value any
---@return table?|KeyError
function dict.put(x, ks, value)
	return dict.set(x, ks, value, true)
end

dict.force_set = dict.put
dict.setf = dict.force_set

---Check if keys exist
---@param x table
---@param ks table
---@return boolean
function dict.has(x, ks)
	if type(ks) ~= "table" then
		ks = { ks }
	end

	for i = 1, #ks - 1 do
		local k = ks[i]
		local v = as.value(x[k])

		if type(v) ~= "table" then
			return false
		else
			x = v
		end
	end

	return x[ks[#ks]] ~= nil
end

---Check if keys exist and return the value.
---@param x table
---@param ks table
---@param default? (fun(): any)
---@param opts? {throw?: boolean, raise?: boolean}
---@return any, table?
function dict.get(x, ks, default, opts)
	opts = opts or {}
	if type(ks) ~= "table" then
		ks = { ks }
	end

	for i = 1, #ks - 1 do
		local k = ks[i]
		local v = as.value(x[k])

		if type(v) ~= "table" then
			if default then
				return as.value(default()), x
			else
				local err = KeyError:new(k, { path = ks, level = x })
				if opts.raise or opts.throw then
					err()
				else
					return err
				end
			end
		else
			x = v
		end
	end

	local v = as.value(x[ks[#ks]])
	if v ~= nil then
		return v, x
	elseif default then
		return as.value(default()), x
	else
		local err = KeyError:new(ks[#ks], { path = ks, level = x })
		if opts.raise or opts.throw then
			err()
		else
			return err
		end
	end
end

---@param x table
---@param f (fun(key: any, value: any): any)
---@return table
function dict.map(x, f)
	local res = {}
	for key, value in pairs(x) do
		res[key] = as.value(f(key, as.value(value)))
	end
	return res
end

---@param x table
---@param f fun(key: any, value: any): boolean
---@param map fun(key: any, value: any): any
---@return table
function dict.filter(x, f, map)
	local res = {}
	for key, value in pairs(x) do
		value = as.value(value)
		if f(key, value) then
			res[key] = map and as.value(map(value)) or value
		end
	end
	return res
end

---@param x table
---@param y table
---@param cmp? fun(x_value: any, y_value: any): boolean
---@param res? table
---@return table
function dict.compare(x, y, cmp, res)
	res = res or {}
	cmp = cmp or function(a, b)
		return a == b
	end

	for key, value in pairs(x) do
		value = as.value(value)
		local y_value = as.value(y[key])

		if type(value) == "table" and type(y_value) == "table" then
			res[key] = {}
			dict.compare(value, y_value, cmp, res[key])
		else
			res[key] = cmp(value, y_value)
		end
	end

	return res
end

---@param x table
---@param y table
---@param cmp? fun(x_value: any, y_value: any): boolean
---@return boolean
function dict.equal(x, y, cmp)
	cmp = cmp or function(a, b)
		return a == b
	end

	for key, value in pairs(x) do
		value = as.value(value)
		local y_value = as.value(y[key])

		if type(value) == "table" and type(y_value) == "table" then
			local ok = dict.equal(value, y_value, cmp)
			if not ok then
				return false
			end
		elseif not cmp(value, y_value) then
			return false
		end
	end

	return true
end

---@param x table
---@return boolean
function dict.is_dict(x)
	is.table(x, { assert = true, prefix = "x" })
	local n = 0
	for _ in pairs(x) do
		n = n + 1
	end
	return n ~= #x
end

---@alias dict.select.key string|(fun(key: any, value: any): boolean)
---@alias dict.select.keys dict.select.key|dict.select.key[]
---@alias dict.select.filtermap table<dict.select.keys, fun(key: any, value: any): any>

---@param s any
---@param filtermap dict.select.filtermap
---@return boolean
local function matches(key, value, filtermap)
	local function match(pattern)
		pattern = as.value(pattern)
		if is.list(pattern) then
			for i = 1, #pattern do
				print(pattern[i])
				if match(pattern[i]) then
					return true
				end
			end
		elseif is.Callable(pattern) then
			if pattern(key, value) then
				return true
			end
		elseif is.string(pattern) then
			if string.match(tostring(key), pattern) then
				return true
			end
		elseif pattern == value then
			return true
		else
			return false
		end
	end

	for pattern, mapper in pairs(filtermap) do
		if match(pattern) then
			return true
		end
	end

	return false
end

---When filtermap consists of a string or string[], it will be matched against the key
---@param x table
---@param filtermap dict.select.filtermap
---@return table
function dict.select(x, filtermap)
	local res = {}
	for key, value in pairs(x) do
		value = as.value(value)
		if matches(key, value, filtermap) then
			res[key] = value
		end
	end
	return res
end

function dict.flatten(x, opts)
	opts = opts or {}
	local sep = opts.sep or "."
	local result = opts.result or {}
	local parent_key = opts.parent_key
	local function create_key(k)
		if parent_key then
			return parent_key .. sep .. k
		else
			return k
		end
	end

	for key, value in pairs(x) do
		if type(value) == "table" then
			dict.flatten(value, {
				sep = sep,
				result = result,
				parent_key = create_key(key),
			})
		else
			result[create_key(key)] = value
		end
	end

	return result
end

---@param x? table
---@param y? table
---@param force? boolean
---@return table
function dict.merge(x, y, force)
	local function join_tables(_x, _y, _force, visited)
		visited = visited or setmetatable({}, { __mode = "k" })
		local cache = function(a, b)
			visited[a] = visited[a] or {}
			visited[a][b] = true
		end

		for key, value in pairs(_y) do
			local x_value = as.value(_x[key])
			local y_value = as.value(value)
			local x_type = type(x_value)
			local y_type = type(y_value)
			local x_is_table = x_type == "table"
			local y_is_table = y_type == "table"

			if x_value == nil then
				_x[key] = y_value
			elseif y_is_table then
				if x_is_table then
					join_tables(x_value, y_value, _force, visited)
					cache(y_value, x_value)
				elseif force then
					_x[key] = y_value
				end
			elseif force then
				_x[key] = y_value
			elseif x_value == nil then
				_x[key] = y_value
			end
		end
	end

	if x and y then
		join_tables(x, y, force)
		return x
	elseif y then
		return y
	elseif x then
		return x
	end

	return {}
end

---@param x? table
---@param y? table
---@return table
function dict.force_merge(x, y)
	return dict.merge(x, y, true)
end

dict.mergef = dict.force_merge

function dict.set_unless(x, ks, value)
	if not dict.has(x, ks) then
		return dict.set(x, ks, as.value(value), false)
	end
end

function dict.from_keys(ks, default_fn)
	local res = {}
	for i = 1, #ks do
		res[ks[i]] = default_fn()
	end
	return res
end

function dict.each(x, callback)
	for key, value in pairs(x) do
		callback(key, as.value(value))
	end
end

function dict.items(x)
	local res = {}
	local ind = 1

	for key, value in pairs(x) do
		res[ind] = { key, value }
		ind = ind + 1
	end

	return res
end

function dict.from_zipped(zipped)
	local out = {}
	dict.each(zipped, function(z)
		out[z[1]] = z[2]
	end)
	return out
end

function dict.partition(x, fn)
	local result = { {}, {} }
	for key, value in pairs(x) do
		value = as.value(value)
		if fn(value) then
			result[1][key] = value
		else
			result[2][key] = value
		end
	end
	return result
end

function dict.reduce(x, acc, f)
	acc = as.value(acc)
	for key, value in pairs(x) do
		value = as.value(value)
		acc = f(key, acc, value)
	end
	return acc
end

function dict.all(t, f)
	for key, value in pairs(t) do
		value = as.value(value)
		if f then
			if not f(key, value) then
				return false
			end
		elseif not value then
			return false
		end
	end

	return true
end

function dict.some(t, f)
	for key, value in pairs(t) do
		value = as.value(value)
		if f then
			if f(key, value) then
				return true
			end
		elseif value then
			return true
		end
	end

	return false
end

---@param x table
---@param ks any
---@param update fun(key: any, value: any, level: table): any
---@param opts? dict.get.opts
---@return any, table?
function dict.update(x, ks, update, opts)
	ks = as.list(ks)
	local value, level = dict.get(x, ks, nil, opts)

	if is.KeyError(value) then
		return value
	else
		level[ks[#ks]] = as.value(update(key, value, level))
	end

	return new, level
end

---@param x table
---@param ks any
---@param opts? dict.get.opts
---@return any, table?
function dict.pop1(x, ks, opts)
  ks = as.list(ks)
	local value, level = dict.get(x, ks, nil, opts)

  if is.KeyError(value) then
    return value, nil
  else
    level[ks[#ks]] = nil
    return value, level
  end
end

---@param x table
---@param ks any
---@param opts? dict.get.opts
---@return any, table
function dict.pop(x, ks, opts)
	local res = {}
	local args = as.list(ks)
	local ind = 1

	for i = 1, #args do
		local ks = as.list(args[i])
		local value = dict.pop1(x, ks, opts)
		res[ind] = value
		ind = ind + 1
	end

	return res, x
end

package.user.lib.dict = dict
