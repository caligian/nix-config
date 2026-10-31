if vim.g.loaded_lua_utils then
	return
end

inspect = require("inspect")

---@class Callable
---@field __call fun(self, ...: any): any

---@alias callable function|Callable
---@alias object class | instance
---@alias num number
---@alias str string
---@alias int integer
---@alias func function
---@alias bool boolean
---@alias handle file*
---@alias na nil

package.user = {}
package.user.state = {}
package.user.config = {
	workspace = {
		check_depth = 10,
		marker = { ".PROJECT" },
	},
}

package.user.lib = {}
package.user.lib.inspect = inspect
package.user.lib.G = {}
package.user.lib.NIL = setmetatable({}, {
	__tostring = function(_)
		return "nil"
	end,
})

---@type {[string]: function}
package.user.lib.guards = {}

---Contains all classes made by the user
---@type {[string]: class}
package.user.lib.classes = {}

package.user.lib.is = {}
package.user.lib.is.__index = package.user.lib.guards
setmetatable(package.user.lib.is, package.user.lib.is)

package.user.lib.as = {}
package.user.lib.as.__index = {}
setmetatable(package.user.lib.as, package.user.lib.as)

package.user.lib.isa = {}
package.user.lib.isa.__index = {}
setmetatable(package.user.lib.isa, package.user.lib.isa)

---Exhaustive list of all possible metamethods.
---TODO: Restrict only to luajit (I have to think about this in the future)
---@type {[string]: string}
package.user.lib.operators = {
	len = "__len",
	concat = "__concat",
	pow = "__pow",
	mod = "__mod",
	pairs = "__pairs",
	ipairs = "__ipairs",
	add = "__add",
	sub = "__sub",
	mul = "__mul",
	div = "__div",
	unm = "__unm",
	call = "__call",
	index = "__index",
	newindex = "__newindex",
	lt = "__lt",
	le = "__le",
	eq = "__eq",
	tostring = "__tostring",
	metatable = "__metatable",
	mode = "__mode",
	gc = "__gc",
	__len = "__len",
	__concat = "__concat",
	__pow = "__pow",
	__mod = "__mod",
	__pairs = "__pairs",
	__ipairs = "__ipairs",
	__add = "__add",
	__sub = "__sub",
	__mul = "__mul",
	__div = "__div",
	__unm = "__unm",
	__call = "__call",
	__index = "__index",
	__newindex = "__newindex",
	__lt = "__lt",
	__le = "__le",
	__eq = "__eq",
	__tostring = "__tostring",
	__metatable = "__metatable",
	__mode = "__mode",
	__gc = "__gc",
	["+"] = "__add",
	["-"] = "__sub",
	["*"] = "__mul",
	["/"] = "__div",
	["-1"] = "__unm",
	["()"] = "__call",
	["[]"] = "__index",
	["[]="] = "__newindex",
	["<"] = "__lt",
	["<="] = "__le",
	["=="] = "__eq",
	[".."] = "__concat",
}

package.user.lib.builtin_types = {
	"boolean",
	"string",
	"number",
	"function",
	"userdata",
	"thread",
	"table",
	"nil",
}

---User defined types
---@type {[string]: boolean}
package.user.lib.types = {
	list = true,
	dict = true,
	boolean = true,
	string = true,
	number = true,
	["function"] = true,
	userdata = true,
	thread = true,
	table = true,
	["nil"] = true,
	class = true,
	instance = true,
}

---@param x any
---@return boolean
function package.user.lib.defined(x)
	return x ~= nil
end

---@param x any
---@return boolean
function package.user.lib.undefined(x)
	return x == nil or x == package.user.lib.NIL
end

---@param x any
---@return any
function package.user.lib.as.value(x)
	if x == package.user.NIL then
		return nil
	else
		return x
	end
end

---@param x any
---@return any[]
function package.user.lib.as.list(x, force)
	x = package.user.lib.as.value(x)
	if force then
		return { x }
	elseif type(x) == "table" then
		return x
	else
		return { x }
	end
end

---Iterate over all entries. If the callback returns `false`,
---iteration stops early (like `break`).
---@param x table
---@param fn fun(key: string|integer, value: any): boolean?
---@return table  -- returns x for chaining
function package.user.lib.each(x, fn)
	for key, value in pairs(x) do
		value = package.user.lib.as.value(value)
		key = package.user.lib.as.value(key)

		if fn(key, value) == false then
			break
		end
	end
	return x
end

---Return true if any entry satisfies the predicate.
---Short-circuits on the first match.
---@param x table
---@param fn fun(key: string|integer, value: any): boolean
---@return boolean
function package.user.lib.any(x, fn)
	x = package.user.lib.as.value(x)
	for key, value in pairs(x) do
		if fn(key, value) then
			return true
		end
	end
	return false
end

---Return true if every entry satisfies the predicate.
---Short-circuits on the first failure. Vacuously true for empty tables.
---@param x table
---@param fn fun(key: string|integer, value: any): boolean
---@return boolean
function package.user.lib.all(x, fn)
	x = package.user.lib.as.value(x)
	for key, value in pairs(x) do
		if not fn(key, value) then
			return false
		end
	end
	return true
end

---@param x any
---@return boolean
function package.user.lib.is.null(x)
	x = package.user.lib.as.value(x)
	return x == package.user.NIL or x == nil
end

function package.user.lib.is.Callable(x)
	x = package.user.lib.as.value(x)
	if type(x) == "table" then
		local mt = getmetatable(x)
		return mt.__call ~= nil
	else
		return false
	end
end

function package.user.lib.is.callable(x)
	return type(x) == "function" or package.user.is.Callable(x)
end

---@param tbl table
---@return  {[1]: (string|integer)[], [2]: any}[]
function package.user.lib.items(tbl)
	local res = {}
	for key, value in pairs(tbl) do
		res[#res + 1] = { key, value }
	end
	return res
end

---@param tbl table
---@return any[]
function package.user.lib.values(tbl)
	local res = {}
	for _, value in pairs(tbl) do
		res[#res + 1] = value
	end
	return res
end

---@param tbl table
---@return (string|integer)[]
function package.user.lib.keys(tbl)
	local res = {}
	for key, _ in pairs(tbl) do
		res[#res + 1] = key
	end
	return res
end

---@param x table
---@param name string
---@param value any
---@return table
function package.user.lib.on(x, name, value)
	local mt = getmetatable(x) or x
	local ops = package.user.operators

	assert(ops[name], "Invalid operator string provided: " .. tostring(name))
	mt[ops[name]] = value

	return setmetatable(x, mt)
end

---If metatable is not set or __index is undefined, reference to self
---@param x table
---@return table?
function package.user.lib.refself(x)
	local mt = getmetatable(x)
	if mt and mt.__index then
		return
	elseif mt then
		mt.__index = x
	else
		x.__index = x
		mt = x
	end
	return setmetatable(x, mt)
end

---@param x table
---@param ks (string|integer)[]
---@return any?
function package.user.lib.mget(x, ks)
	local mt = getmetatable(x)
	if not mt then
		return
	end

	return package.user.lib.get(mt, ks)
end

---@param x table
---@param ks (string|integer)[]
---@param value any
---@return boolean
function package.user.lib.mset(x, ks, value)
	local mt = getmetatable(x)
	if not mt then
		return false
	else
		return package.user.lib.set(mt, ks, value)
	end
end

---Force set a value
---@param x table
---@param ks (string|integer)[]
---@param value any
function package.user.lib.setf(x, ks, value)
	x = package.user.lib.as.value(x)
	ks = type(ks) ~= "table" and { ks } or ks
	local l = #ks
	local dst = x

	for i = 1, l - 1 do
		local k = ks[i]
		dst[k] = {}
		dst = dst[k]
	end

	dst[ks[l]] = value
end

---Update package.user table
---@param x table
---@param ks (string|integer)[]
---@param value any
---@return boolean
function package.user.lib.set(x, ks, value)
	x = package.user.lib.as.value(x)
	ks = type(ks) ~= "table" and { ks } or ks
	local l = #ks
	local dst = x

	for i = 1, l - 1 do
		local k = ks[i]
		local v = dst[k]

		if type(v) ~= "table" then
			return false
		else
			dst = v
		end
	end

	dst[ks[l]] = value
	return true
end

---Check if a key exists
---@param x table
---@param ks (string|integer)[]
---@return boolean
function package.user.lib.has(x, ks)
	x = package.user.lib.as.value(x)
	ks = type(ks) ~= "table" and { ks } or ks
	local l = #ks
	local dst = x

	for i = 1, l - 1 do
		local k = ks[i]
		local v = dst[k]

		if type(v) ~= "table" then
			return false
		else
			dst = v
		end
	end

	return dst[ks[l]] ~= nil
end

---Get value from package.user
---@param x table
---@param ks (string|integer)[]
---@return any?
function package.user.lib.get(x, ks)
	x = package.user.lib.as.value(x)
	ks = type(ks) ~= "table" and { ks } or ks
	local l = #ks
	local dst = x

	for i = 1, l - 1 do
		local k = ks[i]
		local v = dst[k]

		if type(v) ~= "table" then
			return
		else
			dst = v
		end
	end

	return dst[ks[l]]
end

---Unset key from package.user.table
---@param x table
---@param ks (string|integer)[]
---@return any?
function package.user.lib.unset(x, ks)
	x = package.user.lib.as.value(x)
	ks = type(ks) ~= "table" and { ks } or ks
	local l = #ks
	local dst = x

	for i = 1, l - 1 do
		local k = ks[i]
		local v = dst[k]

		if type(v) ~= "table" then
			return
		else
			dst = v
		end
	end

	local v = dst[ks[l]]
	dst[ks[l]] = nil

	return v
end

---@param x table
---@param fn fun(key: integer|string, value: any): any
---@return table
function package.user.lib.apply(x, fn)
	x = package.user.lib.as.value(x)
	local res = {}

	for key, value in pairs(x) do
		res[key] = fn(key, value)
	end

	return res
end

---@param x table
---@param fn fun(key: integer|string, value: any): boolean
---@return table
function package.user.lib.filter(x, fn)
	x = package.user.lib.as.value(x)
	local res = {}

	for key, value in pairs(x) do
		if fn(key, value) then
			res[key] = value
		end
	end

	return res
end

---@param x table
---@param init any
---@param fn fun(key: string|integer, acc: any, value: any): any
---@return any
function package.user.lib.reduce(x, init, fn)
	x = package.user.lib.as.value(x)
	local res = package.user.lib.as.value(init)

	for key, value in pairs(x) do
		res = fn(key, res, value)
		res = package.user.lib.as.value(res)
	end

	return res
end

---@param filename string
---@param mode? string
---@param fn fun(fh: file*): any
---@return boolean, any
function package.user.lib.open_and_then(filename, mode, fn)
	local ok
	local fh, msg = io.open(filename, mode or "r")
	msg = package.user.lib.as.value(msg)

	if not fh then
		return false, msg
	end

	ok, msg = pcall(fn, fh)
	fh:close()

	return ok, msg
end

---@param filename string
---@param mode? string
---@return boolean, string?
function package.user.lib.bslurp(filename, mode)
	mode = mode or "r"
	mode = not string.match(mode, "b") and (mode .. "b") or mode
	return package.user.lib.open_and_then(filename, mode, function(fh)
		return fh:read("*a")
	end)
end

---@param filename string
---@param mode? string
---@param contents string|string[]
---@return boolean, string?
function package.user.lib.bspit(filename, mode, contents)
	mode = mode or "w"
	mode = not string.match(mode, "b") and (mode .. "b") or mode
	return package.user.lib.spit(filename, mode, contents)
end

---@param filename string
---@param mode? string
---@return boolean, string?
function package.user.lib.slurp(filename, mode)
	mode = mode or "r"
	return package.user.lib.open_and_then(filename, mode, function(fh)
		return fh:read("*a")
	end)
end

---@param filename string
---@param mode? string
---@param contents string|string[]
---@return boolean, string?
function package.user.lib.spit(filename, mode, contents)
	contents = package.user.lib.as.value(contents)
	contents = type(contents) == "table" and table.concat(contents, "\n") or contents
	mode = mode or "w"

	assert(type(contents) == "string", "contents= is not of type string")

	return package.user.lib.open_and_then(filename, mode, function(fh)
		local ok, err = fh:write(contents)
		if not ok then
			error(err)
		end
	end)
end

---@param values table<string,any>
function package.user.lib.global(values)
	package.user.lib.unfreeze_globals()
	for name, fn in pairs(values) do
		package.user.lib.G[name] = fn
		_G[name] = fn
	end
	package.user.lib.freeze_globals()
end

---@param x any
---@return string
function package.user.lib.dump(x)
	local tp = type(x)
	if tp == "table" then
		local mt = getmetatable(x)
		if mt and mt.__tostring then
			return mt.__tostring(x)
		else
			return inspect(x, { indent = "  " })
		end
	else
		return tostring(x)
	end
end

---@param x any
---@return string
function package.user.lib.pp(x)
	local s = package.user.lib.dump(x)
	return s
end

---@param x any
---@return any
function package.user.lib.rtostring(x)
	if type(x) ~= "table" then
		return tostring(x)
	elseif x.__tostring then
		return x:__tostring()
	end

	local res = {}
	for key, value in pairs(x) do
		if type(value) == "table" and value.__tostring then
			res[key] = value:__tostring()
		else
			res[key] = package.user.lib.rtostring(value)
		end
	end

	return package.user.lib.dump(res)
end

---@param ... any
---@return any[]
function package.user.lib.pack(...)
	local args = { ... }
	local nargs = select("#", ...)
	local res = {}

	for i = 1, nargs do
		local value = args[i]
		res[#res + 1] = (value == nil and package.user.NIL) or value
	end

	return res
end

---@param msg string
---@param ... any
---@return string
function package.user.lib.sprintf(msg, ...)
	local args = package.user.lib.pack(...)
	local res = {}

	for i = 1, #args do
		res[#res + 1] = package.user.lib.dump(args[i])
	end

	return string.format(msg, unpack(res))
end

---@param msg string
---@param ... any
---@return string
function package.user.lib.printf(msg, ...)
	local args = package.user.lib.pack(...)
	local res = {}

	for i = 1, #args do
		res[#res + 1] = package.user.lib.dump(args[i])
	end

	local s = string.format(msg, unpack(res))
	print(s)

	return s
end

---@param msg string
---@param ... any
function package.user.lib.errorf(msg, ...)
	error(package.user.lib.sprintf(msg, ...))
end

---@param x table|string
---@return integer
function package.user.lib.size(x)
	if type(x) == "string" then
		return #x
	end

	local size = 0
	for _, _ in pairs(x) do
		size = size + 1
	end
	return size
end

---@param x table|string
---@return integer
function package.user.lib.length(x)
	return #x
end

---@param x? table
---@param mt? table
---@return table
function package.user.lib.bless(x, mt)
	x = x or {}
	mt = mt or x
	return setmetatable(x, mt)
end

---@param x? any
---@return boolean
function package.user.lib.callable(x)
	local x_tp = type(x)
	if x_tp == "function" then
		return true
	elseif x_tp == "table" and x.__call then
		return true
	else
		return false
	end
end

---@param x any
---@return boolean
function package.user.lib.sequence(x)
	local x_tp = type(x)
	if x_tp == "table" then
		return size(x) == package.user.lib.length(x)
	elseif x_tp == "string" then
		return true
	else
		return false
	end
end

function package.user.lib.freeze_globals()
	local __newindex = function(_, key, value)
		errorf("Attempting to add value to a locked global table at key %s: %s", key, value)
	end

	local mt = package.user.lib.as.value(getmetatable(_G) or {})
	local old = mt.__newindex
	mt.__newindex = __newindex
	mt.__prev_newindex = old
	mt.__locked = true

	setmetatable(_G, mt)
end

function package.user.lib.unfreeze_globals()
	local mt = package.user.lib.as.value(getmetatable(_G) or {})
	if not mt or not mt.__locked then
		return
	end

	mt.__newindex = mt.__prev_newindex
	mt.__prev_newindex = nil
	mt.__locked = false

	setmetatable(_G, mt)
end

sequence = package.user.lib.sequence
bless = package.user.lib.bless
dump = package.user.lib.dump
pp = package.user.lib.pp
rtostring = package.user.lib.rtostring
pack = package.user.lib.pack
sprintf = package.user.lib.sprintf
printf = package.user.lib.printf
errorf = package.user.lib.errorf
size = package.user.lib.size
length = package.user.lib.length
bless = package.user.lib.bless
unpack = unpack or table.unpack
defined = package.user.lib.defined
undefined = package.user.lib.undefined
global = package.user.lib.global
callable = package.user.lib.callable
freeze_globals = package.user.lib.freeze_globals
unfreeze_globals = package.user.lib.unfreeze_globals
is = package.user.lib.is
as = package.user.lib.as

global({
	sequence = package.user.lib.sequence,
	unpack = package.user.lib.unpack,
	defined = package.user.lib.defined,
	undefined = package.user.lib.undefined,
	inspect = package.user.lib.inspect,
	dump = package.user.lib.dump,
	is = package.user.lib.is,
	as = package.user.lib.as,
	pp = package.user.lib.pp,
	rtostring = package.user.lib.rtostring,
	pack = package.user.lib.pack,
	sprintf = package.user.lib.sprintf,
	printf = package.user.lib.printf,
	errorf = package.user.lib.errorf,
	size = package.user.lib.size,
	length = package.user.lib.length,
	bless = package.user.lib.bless,
	callable = package.user.lib.callable,
})

unfreeze_globals()

vim.g.loaded_lua_utils = true
