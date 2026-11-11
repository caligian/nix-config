if vim.g.loaded_lua_utils_definitions then
	return
end

vim.g.loaded_lua_utils_definitions = true

package.user = {}
package.user.state = {}
package.user.lib = {}
package.user.config = {}

local lib = package.user.lib
local config = package.user.config
local Gmt = getmetatable(_G) or {}
local Gnewindex = Gmt and Gmt.__newindex
local globals = {
	Spec = true,
	Specification = true,
	Predicate = true,
	union = true,
	maybe = true,
	format = true,
	substr = true,
	replace = true,
	Ok = true,
	Err = true,
	rthread = true,
	rpcall = true,
	rwrap = true,
	partial = true,
	predicate = true,
	paste0 = true,
	concat = true,
	call = true,
	copy = true,
	inspect = true,
	dump = true,
	pp = true,
	sprintf = true,
	printf = true,
	errorf = true,
	pack = true,
	is = true,
	as = true,
	global = true,
	globals = true,
	unglobal = true,
	open_and_then = true,
	spit = true,
	slurp = true,
	dirname = true,
	find_files = true,
	list_files = true,
	chdir = true,
	rmdir = true,
	touch = true,
	mkdir = true,
	abspath = true,
	getcwd = true,
}

Gmt.__old_newindex = Gnewindex
Gmt.__newindex = function(self, key, value)
  rawset(self, key, value)
	-- if dont_set[key] and not _G[key] then
	-- 	package.user.lib.printf("WARNING: Attempting to set global {%s}, ignoring", key)
	-- 	return
	-- else
	-- 	rawset(self, key, value)
	-- 	if Gnewindex then
	-- 		Gnewindex(self, key, value)
	-- 	end
	-- end
end

function global(name, value)
	rawset(_G, name, value)
end

function globals(variables)
	for key, value in pairs(variables) do
		global(key, value)
	end
end

function unglobal(name)
	local prev = _G[name]
	_G[name] = nil
	return prev
end

setmetatable(_G, Gmt)

lib.global = global
lib.globals = globals
lib.unglobal = unglobal

---@class callable
---@field __call fun(self, ...: any): any

---@alias Callable function|callable
---@alias object class | instance
---@alias num number
---@alias str string
---@alias int integer
---@alias func function
---@alias bool boolean
---@alias handle file*
---@alias na nil

config.workspace = {
	marker = { { ".PROJECT" }, ".git" },
}

lib.inspect = require("inspect")
lib.G = {}
lib.NIL = setmetatable({}, {
	__tostring = function(_)
		return "nil"
	end,
})

lib.is = {}
lib.is.__index = lib.guards
setmetatable(lib.is, lib.is)

lib.as = {}
lib.as.__index = {}
setmetatable(lib.as, lib.as)

---Exhaustive list of all possible metamethods.
---TODO: Restrict only to luajit (I have to think about this in the future)
---@type {[string]: string}
lib.operators = {
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

lib.types = {}

---@type string[]
lib.types.builtin = {
	"boolean",
	"string",
	"number",
	"function",
	"userdata",
	"thread",
	"table",
	"nil",
}

---@param x any
---@return boolean
function lib.defined(x)
	return x ~= nil
end

---@param x any
---@return boolean
function lib.undefined(x)
	return x == nil or x == lib.NIL
end

---@param x any
---@return any
function lib.as.value(x)
	if x == lib.NIL then
		return nil
	else
		return x
	end
end

---@param x any
---@return any[]
function lib.as.list(x, force)
	x = lib.as.value(x)
	if force then
		return { x }
	elseif type(x) == "table" then
		return x
	else
		return { x }
	end
end

---@param x table
---@param name string
---@param value any
---@return table
function lib.on(x, name, value)
	local mt = getmetatable(x) or x
	local ops = package.user.operators

	assert(ops[name], "Invalid operator string provided: " .. tostring(name))
	mt[ops[name]] = value

	return setmetatable(x, mt)
end

---If metatable is not set or __index is undefined, reference to self
---@param x table
---@return table?
function lib.bless(x)
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

---@param filename string
---@param mode? string
---@param fn fun(fh: file*): any
---@return boolean, any
function lib.open_and_then(filename, mode, fn)
	local ok
	local fh, msg = io.open(filename, mode or "r")
	msg = lib.as.value(msg)

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
function lib.bslurp(filename, mode)
	mode = mode or "r"
	mode = not string.match(mode, "b") and (mode .. "b") or mode
	return lib.open_and_then(filename, mode, function(fh)
		return fh:read("*a")
	end)
end

---@param filename string
---@param mode? string
---@param contents string|string[]
---@return boolean, string?
function lib.bspit(filename, mode, contents)
	mode = mode or "w"
	mode = not string.match(mode, "b") and (mode .. "b") or mode
	return lib.spit(filename, mode, contents)
end

---@param filename string
---@param mode? string
---@return boolean, string?
function lib.slurp(filename, mode)
	mode = mode or "r"
	return lib.open_and_then(filename, mode, function(fh)
		return fh:read("*a")
	end)
end

---@param filename string
---@param mode? string
---@param contents string|string[]
---@return boolean, string?
function lib.spit(filename, mode, contents)
	contents = lib.as.value(contents)
	contents = type(contents) == "table" and table.concat(contents, "\n") or contents
	mode = mode or "w"

	assert(type(contents) == "string", "contents= is not of type string")

	return lib.open_and_then(filename, mode, function(fh)
		local ok, err = fh:write(contents)
		if not ok then
			error(err)
		end
	end)
end

---@param x any
---@return string
function lib.dump(x)
	local tp = type(x)
	if tp == "table" then
		return lib.inspect(x, { indent = "  " })
	else
		return tostring(x)
	end
end

---@param x any
---@return string
function lib.pp(x)
	local s = lib.dump(x)
	print(s)
	return s
end

--@param ... any
---@return any[]
function lib.pack(...)
	local args = { ... }
	local nargs = select("#", ...)
	local res = {}

	for i = 1, nargs do
		local value = args[i]
		res[#res + 1] = (value == nil and lib.NIL) or value
	end

	return res
end

---@param msg string
---@param ... any
---@return string
function lib.sprintf(msg, ...)
	local args = lib.pack(...)
	local res = {}

	for i = 1, #args do
		res[#res + 1] = lib.dump(args[i])
	end

	return string.format(msg, unpack(res))
end

---@param msg string
---@param ... any
---@return string
function lib.printf(msg, ...)
	local args = lib.pack(...)
	local res = {}

	for i = 1, #args do
		res[#res + 1] = lib.dump(args[i])
	end

	local s = string.format(msg, unpack(res))
	print(s)

	return s
end

---@param msg string
---@param ... any
function lib.errorf(msg, ...)
	error(lib.sprintf(msg, ...))
end

---@param x table|string
---@return integer
function lib.size(x)
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
function lib.length(x)
	return #x
end

local copy = {}
copy.__index = rawget
setmetatable(copy, copy)
lib.copy = copy

---Shallow copy table
---@param x table src table
---@param res? table dest table
---@return table
function copy.copy(x, res)
	res = res or {}
	local mt = getmetatable(x)

	for key, value in pairs(x) do
		res[key] = value
	end

	if mt then
		setmetatable(res, mt)
	end

	return res
end

---Deep copy table
---@param x table src table
---@param res? table dest table
---@param cache? table Optional table containing caches
---@return table
function copy.deep(x, res, cache)
	local mt = getmetatable(x)
	res = res or {}
	cache = cache or {}
	cache[x] = true

	for key, value in pairs(x) do
		if type(value) == "table" then
			if cache[value] then
				res[key] = value
			else
				res[key] = {}
				cache[value] = true
				copy.deep(value, res[key], cache)
			end
		else
			res[key] = value
		end
	end

	if mt then
		setmetatable(res, mt)
	end

	return res
end

---Copy table
---@param x table
---@param deep? boolean
---@return table
function copy:__call(x, deep)
	if deep then
		return copy.deep(x)
	else
		return copy.copy(x)
	end
end

inspect = lib.inspect
pp = lib.pp
printf = lib.printf
sprintf = lib.sprintf
open_and_then = lib.open_and_then
spit = lib.spit
slurp = lib.slurp
copy = lib.copy
errorf = lib.errorf
pack = lib.pack
is = lib.is
as = lib.as
copy = lib.copy

return lib
