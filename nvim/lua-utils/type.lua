if vim.g.loaded_lua_utils_type then
	return
end

require("lua-utils.definitions")

vim.g.loaded_lua_utils_type = true
local lib = package.user.lib

---@alias PredicateCallable fun(x: any): string?
---@alias GuardCallable fun(x: any, opts?: is.opts): boolean, string?
---@alias Predicate.Callable fun(...): (Ok<`T`> | Err<Error> | boolean)?, string?
---@alias UnionSignature class|instance|Union|Predicate|Callable|string|fun(x: any): string?
local copy = lib.copy
local base_class = setmetatable({
	__type = "class",
	__name = "base",
}, { __type = "class" })

lib.format = string.format
lib.repr = lib.sprintf
lib.replace = string.gsub
lib.substr = string.sub

---@class Predicate.opts
---@field pcall? boolean
---@field safe? boolean
---@field throw? boolean
---@field raise? boolean
---@field unwrap? boolean

---@class Predicate<T> : Predicate.class : instance
---@field call fun(...): string?
---@field safe? boolean
---@field message? string
---@field prefix? string
---@overload fun(...): Ok<T> | Err<CallError>

---@class Union : Union.class : instance
---@field signature UnionSignature|UnionSignature[]
---@field display string
---@field opts Predicate.opts | is.opts
---@field any_of nil
---@field all_of nil
---@field validate_signature nil
---@field predicate fun(x: any): string?
---@overload fun(x: any, opts?: is.opts): boolean, string?

---@class Result<T> : Result.class<T> : instance
---@field value? Error|T
---@field metadata? table
---@field err boolean
---@field ok boolean
---@field type "Err" | "Ok"
---@field new nil
---@field initialize nil
---@field issubclass nil
---@field thread nil

---@class Err<E> : Err.class<E> : Result
---@field value Error
---@field err true
---@field ok false
---@field type "Err"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@class Ok<T> : Ok.class<T> : Result<T>
---@field value T
---@field err false
---@field ok true
---@field type "Ok"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@class CallError : CallError.class : Error
---@field fun Callable
---@field args any[]

---@class TypeError : TypeError.class : Error
---@field value any

---@class Error : Error.class : instance
---@field message string
---@field args any[]
---@field new nil
---@field initialize nil
---@field issubclass nil

---@class is.opts
---@field optional? boolean
---@field opt? boolean
---@field assert? boolean
---@field dump? boolean
---@field prefix? string

---@class instance<T>
---@field __name string?
---@field __type "instance"
---@field __class? class
---@field new nil
---@field initialize nil
---@field instanceof fun(self: instance<T>, other: class, opts?: is.opts): boolean, string?

---@class class<T>
---@field new fun(self: T, ...): instance<T>
---@field initialize fun(self: T, ...)
---@field __name string?
---@field __type "class"
---@field __class? class
---@field __tostring function
---@field __index? class
---@field __id string
---@field issubclass fun(self: class<T>, other: class, opts?: is.opts): boolean, string?

---@class predicate.opts
---@field expected string|(fun(x: any): string)
---@field got? fun(x: any): string
---@field format string (default: Expected {expected}, got [{got}] {value})

---@class is.opts
---@field assert? boolean
---@field dump? boolean
---@field prefix? string

--[[
Value conversion stuff
--]]

---@param x any
---@return integer?
function as.integer(x)
	if type(x) == "string" and string.match(x, "^%d+$") then
		return tonumber(x)
	end
end

as.int = as.integer

---@param x any
---@return number?
function as.number(x)
	return tonumber(x)
end

as.num = as.number

---@param x any
---@return function
function as.fun(x)
	if is.callable(x) then
		return function(...)
			return x.__call(x, ...)
		end
	elseif is.fun(x) then
		return x
	else
		return function()
			return x
		end
	end
end

---@generic T
---@param x `T`
---@return `T`?
function as.NIL(x)
	if x == nil then
		return package.user.lib.NIL
	else
		return x
	end
end

as.na = as.NIL

---@param x any
---@return boolean
function as.boolean(x)
	if x then
		return true
	else
		return false
	end
end

as.bool = as.boolean

---@param x any
---@return string
function as.string(x)
	if type(x) == "table" and x.__tostring then
		return tostring(x)
	else
		return lib.dump(x)
	end
end

as.str = as.string

function lib.substitute(msg, subs)
	for key, value in pairs(subs) do
		local pattern = "%%{" .. key .. "%}"
		msg = lib.replace(msg, pattern, lib.dump(value))
	end
	return msg
end

function lib.callable(x)
	if type(x) == "table" then
		local mt = getmetatable(x)
		return mt and mt.__call ~= nil
	else
		return false
	end
end

function lib.Callable(x)
	return lib.callable(x) or type(x) == "function"
end

function lib.call(fn, ...)
	return fn(...)
end

function lib.partial(fn, ...)
	local outer = { ... }
	return function(...)
		local all_args = { unpack(outer) }
		for _, arg in ipairs({ ... }) do
			all_args[#all_args + 1] = arg
		end
		return fn(unpack(all_args))
	end
end

function lib.paste0(...)
	local res = { ... }
	return table.concat(res, "")
end

lib.concat = table.concat
lib.join = table.concat
lib.sort = table.sort

---@class prefixed.opts
---@field key? int | str
---@field message? string

---@param prefix? string
---@param opts? prefixed.opts
function lib.make_message(prefix, opts)
	opts = opts or {}
	local message = opts.message
	local key = opts.key
	local key_str = key
		and lib.call(function()
			if is.integer(key) then
				return lib.format("[%d]", key)
			elseif is.string(key) then
				if key:match("^[a-zA-Z0-9_]+$") then
					return key
				else
					return lib.format('["%s"]', key)
				end
			else
				return lib.format('["%s"]', tostring(key))
			end
		end)

	if prefix and key_str then
		key_str = key_str:sub(1, 1) ~= "[" and lib.paste0(".", key_str) or key_str
		if message then
			return lib.paste0(prefix, key_str, ": ", message)
		else
			return lib.paste0(prefix, key_str)
		end
	elseif key_str then
		if message then
			return lib.paste0(key_str, ": ", message)
		else
			return key_str
		end
	elseif prefix then
		if message then
			return lib.paste0(prefix, ": ", message)
		else
			return prefix
		end
	elseif message then
		return message
	else
		error("Not implemented")
	end
end

--[[
Predicate making functions
--]]

lib.predicate = lib.bless({
	---@type table<string,PredicateCallable>
	predicate = {},
})

---@param fn PredicateCallable
---@param opts? predicate.opts
---@return fun(x: any): string?
function lib.predicate:__call(fn, opts)
	opts = opts or {}
	local expected = opts.expected
	local got = opts.got
	local format = opts.format or "Expected %{expected}, got [%{got}] {%{value}}"

	return function(x)
		if fn(x) then
			return
		end

		return lib.substitute(format, {
			expected = lib.Callable(expected) and expected(x) or expected,
			got = lib.Callable(got) and got(x) or type(x),
			value = x,
		})
	end
end

---@param fn Callable
---@param opts? predicate.opts
---@return PredicateCallable
function lib.predicate.add(name, fn, opts)
	local pred
	if is.class(fn) then
		pred = lib.predicate.class(fn, opts)
	else
		pred = lib.predicate(fn, opts)
	end
	lib.predicate.predicate[name] = pred
	return pred
end

---@param cls class
---@return PredicateCallable
function lib.predicate.class(cls)
	is.class(cls, { assert = true, prefix = "cls" })
	local opts = {
		expected = function()
			return "class." .. cls.__name
		end,
		got = function(x)
			return "instance." .. x.__name
		end,
	}

	return lib.predicate.add(cls.__name, function(x)
		if not is.instance(x) then
			return false
		elseif lib.instanceof(x, cls) then
			return true
		else
			return false
		end
	end, opts)
end

---@param predicates table<string,{[1]: PredicateCallable, [2]: predicate.opts}>
---@return table<string,PredicateCallable>
function lib.predicate.from_table(predicates)
	local res = {}
	for name, spec in pairs(predicates) do
		local this_specs, opts = unpack(spec)
		res[name] = lib.predicate.add(name, this_specs, opts)
	end
	return res
end

function lib.predicate.setup()
	local pred = lib.predicate.predicate

	for _, tp in ipairs(package.user.lib.types.builtin) do
		pred[tp] = lib.predicate(function(x)
			return type(x) == tp
		end, { expected = tp })
	end

	pred.Callable = lib.predicate(function(x)
		local tp = type(x)
		if tp == "function" then
			return true
		elseif tp ~= "table" then
			return false
		end

		local mt = getmetatable(x)
		return mt and mt.__call
	end, { expected = "Callable" })

	pred.callable = lib.predicate(function(x)
		if type(x) ~= "table" then
			return false
		end

		local mt = getmetatable(x)
		return mt and mt.__call ~= nil
	end, { expected = "callable" })

	pred.list = lib.predicate(function(x)
		if not pred.pure(x) then
			return false
		end

		local n = #x
		local actual = 0

		for _, _ in pairs(x) do
			actual = actual + 1
		end

		return n == actual
	end, { expected = "list" })

	pred.dict = lib.predicate(function(x)
		return pred.pure(x) ~= nil and pred.list(x) ~= nil
	end, { expected = "dict" })

	pred.class = lib.predicate(function(x)
		if pred.table(x) ~= nil then
			return false
		elseif pred.impure(x) ~= nil then
			return false
		else
			return x.__type == "class"
		end
	end, { expected = "class" })

	pred.instance = lib.predicate(function(x)
		if pred.table(x) ~= nil then
			return false
		elseif pred.impure(x) ~= nil then
			return false
		else
			return x.__type == "instance"
		end
	end, { expected = "instance" })

	pred.pure = lib.predicate(function(x)
		if type(x) ~= "table" then
			return false
		elseif getmetatable(x) then
			return false
		else
			return true
		end
	end, { expected = "pure table" })

	pred.impure = lib.predicate(function(x)
		if type(x) ~= "table" then
			return false
		elseif getmetatable(x) then
			return true
		else
			return false
		end
	end, { expected = "table with metatable" })

	pred.object = lib.predicate(function(x)
		return is.na(pred.class(x)) or is.na(pred.instance(x))
	end, { expected = "class|instance" })

	pred.integer = lib.predicate(function(x)
		if tonumber(x) and tostring(x):match("^%d+$") then
			return true
		else
			return false
		end
	end, { expected = "integer" })

	pred.num = pred.number
	pred.int = pred.integer
	pred.na = pred["nil"]
	pred.NIL = pred.na
	pred.fun = pred["function"]
end

lib.predicate.setup()

--[[
Guard function utilities. These are the same as predicates 
However they can be plugged into assert and other boolean, string? 
return shape
--]]

lib.guard = lib.bless({})

---@type table<string,GuardCallable>
lib.guard.guard = {}
lib.is.__index = lib.guard.guard

---@param name string?
---@param fn PredicateCallable
---@param opts? predicate.opts
---@return GuardCallable
function lib.guard:__call(name, fn, opts)
	local pred = lib.predicate.add(name, fn, opts)
	return lib.guard.from_predicate(name, pred)
end

---IMPORTANT: This predicate function must be produced with lib.predicate()
---@param name string?
---@param pred PredicateCallable
---@return GuardCallable
function lib.guard.from_predicate(name, pred)
	local f = function(x, opts)
		x = as.value(x)
		opts = opts or {}
		local opt = opts.optional or opts["?"] or opts.opt
		local should_dump = opts.dump
		local prefix = opts.prefix
		local throw = opts.assert

		if prefix or assert then
			should_dump = true
		end

		if opt and x == nil then
			return true
		end

		local msg = pred(x)
		if not msg then
			return true
		elseif throw or should_dump then
			local _msg = lib.make_message(prefix, {
				message = msg,
			})
			if throw then
				error(_msg)
			else
				return false, _msg
			end
		elseif should_dump then
			return false, lib.make_message(prefix, {
				message = msg,
			})
		else
			return false, nil
		end
	end

	lib.guard.guard[name] = f
	is[name] = f
	return f
end

---@param predicates table<string,PredicateCallable>
---@return table<string,GuardCallable>
function lib.guard.from_predicates(predicates)
	local res = {}
	for name, pred in pairs(predicates or {}) do
		res[name] = lib.guard.from_predicate(name, pred)
	end
	return res
end

---@param functions table<string,{[1]: PredicateCallable, [2]: predicate.opts}>
---@return table<string,GuardCallable>
function lib.guard.from_table(functions)
	local res = {}
	for name, spec in pairs(functions or {}) do
		local pred = lib.predicate.add(unpack(spec))
		res[name] = lib.guard.from_predicate(name, pred)
		res[name] = lib.guard.guard[name]
	end
	return res
end

function lib.guard.setup()
	for name, pred in pairs(lib.predicate.predicate) do
		lib.guard.guard[name] = lib.guard.from_predicate(name, pred)
	end
end

lib.guard.setup()

---@param name string
---@param cond fun(x): boolean
---@param opts? predicate.opts
function lib.mkguard(name, cond, opts)
	return lib.guard(name, cond, opts)
end

---@param child instance
---@param parent class
---@param opts? is.opts
---@return boolean, string?
function lib.instanceof(child, parent, opts)
	child = as.value(child)
	parent = as.value(parent)

	is.instance(child, { prefix = "<child>", assert = true })
	is.class(parent, { prefix = "<parent>", assert = true })

	local cls = child.__class
	if cls == parent then
		return true
	end

	while cls do
		if cls == parent then
			return true
		else
			cls = cls.__class
		end
	end

	opts = opts or {}
	local prefix = opts.prefix
	local should_dump = opts.dump
	local throw = opts.assert

	if throw or should_dump then
		local msg = lib.make_message(prefix, {
			message = lib.format("Expected instance.%s", parent.__name),
		})

		if throw then
			error(msg)
		end
		return false, msg
	else
		return false
	end
end

lib.isa = lib.instanceof

---@param child table
---@param parent table
---@param opts? is.opts
---@return boolean, string?
function lib.issubclass(child, parent, opts)
	child = as.value(child)
	parent = as.value(parent)

	is.class(child, {
		prefix = "<child>",
		assert = true,
	})

	if child.__class == parent then
		return true
	end

	local cls = child.__class
	while cls do
		if cls == parent then
			return true
		end
		cls = cls.__class
	end

	opts = opts or {}
	local prefix = opts.prefix
	local should_dump = opts.dump
	local throw = opts.assert

	if throw or should_dump then
		local msg = lib.format("Expected subclass of class.%s", parent.__name)
		local err_msg = lib.make_message(prefix, {
			message = msg,
		})

		if throw then
			error(err_msg)
		else
			return false, err_msg
		end
	else
		return false
	end
end

--[[
Class utilities
--]]

---@generic T
---@overload fun(name: string, parent?: class, opts?: class.opts): class<`T`>
lib.class = lib.bless({})
class = lib.class

---@param cls object
---@return class
function class.class(cls)
	cls = as.value(cls)
	assert(is.object(cls, { prefix = "<cls>", assert = true }))

	if is.instance(cls) then
		return cls.__class
	else
		return cls
	end
end

---@param cls object
---@param name string
---@return any
function class.get(cls, name)
	cls = as.value(cls)
	assert(is.class(cls, { prefix = "<cls>", assert = true }))
	local value = rawget(cls, name)

	if value then
		return value
	end

	local parent = cls.__class
	while not value and parent do
		value = rawget(parent, name)
		parent = parent.__class
	end

	return value
end

---@param cls object
---@param name string
---@return Callable?
function class.method(cls, name)
	cls = as.value(cls)
	local method = class.get(cls, name)
	if method == nil then
		return
	end

	local prefix = lib.format("%s.%s", cls.__name, tostring(name))
	is.callable(method, { prefix = prefix, assert = true })

	return method
end

---@param cls object
---@param names_only? boolean
---@return (class[]|string)?
function class.parents(cls, names_only)
	cls = as.value(cls)
	local parents = {}
	local parent = rawget(cls, "__class")

	while parent do
		parents[#parents + 1] = parent
		parent = rawget(parent, "__class")
	end

	local res = {}
	for i = #parents, 1, -1 do
		if names_only then
			res[#res + 1] = parents[i].__name
		else
			res[#res + 1] = parents[i]
		end
	end

	return res
end

---@param cls object
---@return table
function class.A(cls)
	cls = as.value(cls)
	assert(is.object(cls, { prefix = "<cls>", assert = true }))
	local res = {}

	for key, value in pairs(cls) do
		if not key:match("^__") then
			res[key] = value
		end
	end

	return res
end

---@param cls object
---@return string
function class.name(cls)
	cls = as.value(cls)
	assert(is.object(cls, { prefix = "<cls>", assert = true }))
	return cls.__name
end

---@param cls object
---@return table
function class.M(cls)
	cls = as.value(cls)
	assert(is.object(cls, { prefix = "<cls>", assert = true }))
	local res = {}

	for key, value in pairs(cls) do
		if key:match("^__") then
			res[key] = value
		end
	end

	return res
end

---@param name string
---@param parent? class
---@param static? table<string,boolean>
---@return class
function class.new(name, parent, static)
	name = as.value(name)
	parent = as.value(parent)
	parent = parent or base_class

	is.string(name, { prefix = "name", assert = true })
	is.class(parent, { prefix = "<parent>", assert = true })

	local new = {}
	new.__id = tostring(new):gsub("^table: ", "")
	new.issubclass = lib.issubclass
	new.__name = name
	new.__class = parent
	new.__index = parent
	new.__type = "class"
	new.__tostring = parent.__tostring
		or function(self)
			local attribs = {}
			for key, _ in pairs(self) do
				if not tostring(key):match("^__") then
					attribs[#attribs + 1] = key
				end
			end

			return lib.format("%s.%s [%s] { %s }", self.__type, self.__name, self.__id, table.concat(attribs, ", "))
		end

	lib.mkguard(name, function(x)
		return is.instance(x) and lib.isa(x, new)
	end, { expected = lib.paste0("instance.", new.__name) })

	for key, value in pairs(parent) do
		if is.na(new[key]) then
			new[key] = value
		end
	end

	new.new = function(self, ...)
		local init = rawget(self, "initialize") or parent and parent.initialize
		if not init then
			error(lib.format("%s: .initialize() is undefined", tostring(self)))
		end

		local obj = class.new_instance(self, static)
		init(obj, ...)

		local not_ok_msg = self.__validate and self.__validate(obj)
		if not_ok_msg then
			error(lib.format("%s: Validation failure:\n%s", tostring(self), not_ok_msg))
		end

		return obj
	end

	return setmetatable(new, parent)
end

---@param cls class
---@param ignore? table<string,boolean>
---@return instance
function class.new_instance(cls, ignore)
	local new = setmetatable({}, cls)
	local inst_id = tostring(new):gsub("^table: ", "")
	new.__id = inst_id

	for key, value in pairs(cls) do
		if key ~= "__id" and not (ignore and ignore[key]) then
			new[key] = value
		end
	end

	---@cast new instance
	new.__type = "instance"
	new.__class = cls
	new.new = nil
	new.issubclass = nil
	new.instanceof = lib.instanceof

	return new
end

---@class class.opts
---@field include? table<string,any>
---@field static? string[]

---@param name string
---@param parent? class
---@return class
function class:__call(name, parent, opts)
	opts = opts or {}
	local ignore = { issubclass = true, new = true }

	if opts.static then
		for i = 1, #opts.static do
			ignore[opts.static[i]] = opts.static[i]
		end
	end

	local new = class.new(name, parent, ignore)

	if opts.include then
		for key, value in pairs(opts.include) do
			new[key] = value
		end
	end

	return new
end

---@class Error.class : class
---@field new fun(self: Error.class, msg: string, ...: any): Error
Error = class("Error")
lib.Error = lib.Error
is.error = is.Error

function Error:initialize(name, msg, ...)
	is.str(name, { assert = true, prefix = "name" })
	is.str(msg, { assert = true, prefix = "message" })

	self.name = name
	self.message = as.value(msg)
	self.args = { ... }
end

---Raise error
function Error:throw()
	error(self:__tostring(self))
end

function Error:__tostring()
	local parents = class.parents(self, true)
	local name = table.concat(parents, ".")
	local args = self.args
	local msg = self.message or "error!"
	return lib.format("%s: %s\nargs: %s", name, msg, lib.dump(args))
end

---@class TypeError.class : Error.class
---@field new fun(self: TypeError.class, msg: string, value: any): TypeError
TypeError = class("TypeError", Error)
lib.TypeError = TypeError

function TypeError:initialize(message, value)
	lib.Error.initialize(self, message, value)
	self.value = value
end

---@class CallError.class : Error.class
---@field new fun(self: CallError.class, msg: string, fun: Callable, args: any[]): CallError
CallError = class("CallError", Error)
lib.CallError = CallError

function CallError:initialize(message, fun, args)
	lib.Error.initialize(self, message, fun, args)
	self.fun = fun
	self.args = args
end

---@class Result.class<T,E> : class
---@field new fun(self: Result<T,E>, value?: E|T, metadata?: table): Result<T,E>
Result = class("Result")
lib.Result = Result
is.result = is.Result
is.res = is.Result

function Result:initialize(value, metadata)
	value = as.value(value)
	metadata = as.value(metadata)
	self.err = is.error(value)
	self.type = self.err and "Err" or "Ok"
	self.ok = self.type ~= "Err"
	self.value = value
	self.metadata = metadata
end

---@generic T
---@return `T`|Error
function Result:unwrap()
	local value = self.value
	if self.err then
		---@cast value Error
		value:throw()
	end

	---@cast value `T`
	return value
end

function Result:__tostring()
	return lib.format(
		"Result.%s { value = %s, metadata = %s }",
		self.type,
		lib.dump(self.value),
		lib.dump(self.metadata)
	)
end

---@class Ok.class<T> : Result.class<T,nil>
---@field new fun(self: Ok.class<T>, value?: T, metadata?: table): Ok<T>
Ok = class("Ok", Result)
lib.Ok = Ok
is.ok = is.Ok

function Ok:initialize(value, metadata)
	return Result.initialize(self, value, metadata)
end

---@class Err.class<E> : Result.class<nil,E>
---@field new fun(self: Err.class<E>, msg: string, metadata?: table): Err<E>
Err = class("Err", Result)
lib.Err = Err
is.err = is.Err

function Err:initialize(msg, metadata)
	return Result.initialize(self, lib.Error:new(msg), metadata)
end

---@generic T
---@param fn fun(...): `T`
---@param ... any
---@return Ok<`T`> | Err<CallError>
function lib.rpcall(fn, ...)
	local ok, msg = pcall(fn, ...)
	if not ok then
		return Err:new(lib.CallError:new(msg, fn, { ... }))
	else
		return Ok:new(msg)
	end
end

---@param fn PredicateCallable
---@return fun(x): Result
lib.rpredicatewrap = function(fn)
	---@param ... any
	---@return Result
	return function(...)
		local msg = fn(...)
		if is.str(msg) then
			return lib.Err:new(lib.CallError:new(msg, fn, { ... }))
		else
			return lib.Ok:new(true)
		end
	end
end

---@param fn PredicateCallable
---@return fun(x): Result
lib.rsafewrap = function(fn)
	---@param ... any
	---@return Result
	return function(...)
		local ok, msg = pcall(fn, ...)
		if not ok then
			msg = as.NIL(msg)
			return lib.Err:new(lib.CallError:new(msg, fn, { ... }))
		else
			return lib.Ok:new(msg)
		end
	end
end

---@param fn PredicateCallable
---@return fun(x): Result
lib.rguardwrap = function(fn)
	---@param ... any
	---@return Result
	return function(...)
		local ok, msg = fn(...)
		if not ok then
			msg = as.NIL(msg)
			return lib.Err:new(lib.CallError:new(msg, fn, { ... }))
		else
			return lib.Ok:new(msg)
		end
	end
end

---@param fn PredicateCallable
---@return fun(x): Result
lib.rwrap = function(fn)
	---@param ... any
	---@return Result
	return function(...)
		local res = fn(...)
		if is.Result(res) then
			return res --[[@as Result]]
		elseif is.str(res) then
			return lib.Err:new(lib.CallError:new(res, fn, { ... }))
		else
			return lib.Ok:new(true)
		end
	end
end

---@param x any
---@param funs (fun(x: any): Result)[]
---@param throw_on_err? boolean
---@return Ok|Err
function lib.rthread(x, funs, throw_on_err)
	local last = x
	if is.result(last) then
		last = last:unwrap()
	end

	for i = 1, #funs do
		local f = funs[i]
		is.Callable(f, { prefix = lib.format("<functions>[%d]", i), assert = true })

		local res = lib.rpcall(f, last)
		if is.err(res) then
			---@cast res Err
			res.metadata = res.metadata or {}
			res.metadata.index = i
			res.metadata.fun = f
			res.metadata.last_value = last

			if throw_on_err then
				res:unwrap()
			else
				---@type Err
				return res
			end
		else
			last = last:unwrap()
		end
	end

	if is.error(last) then
		---@type Err
		local res = Err:new(last)
		return res
	elseif is.res(last) then
		---@type Ok
		return last
	else
		return Result:new(last)
	end
end

---Recursive table spec checking
---@param x table
---@param y table
---@param opts? is.opts
---@return table?
function lib.match(x, y, opts)
	x = as.value(x)
	y = as.value(y)

	is.table(x, { assert = true, prefix = "<x>" })
	is.table(y, { assert = true, prefix = "<y>" })

	opts = opts or {}
	local should_dump = opts.dump
	local throw = opts.assert

	if throw then
		should_dump = true
	end

	local res = not throw and {} or nil
	local err = function(parent, key, value, msg)
		if type(msg) == "string" then
			return TypeError:new(msg, {
				key = key,
				value = value,
				msg = msg,
				parent = parent,
			})
		else
			return false
		end
	end

	local function prefix_msg(prefix, key, msg, ...)
		if type(key) == "number" then
			key = prefix .. lib.format("[%d]", key)
		else
			key = prefix .. "." .. key
		end

		if not msg then
			return lib.format("%s", key)
		else
			msg = lib.format(msg, ...)
			return lib.format("%s: %s", key, msg)
		end
	end

	local function recurse(a, b, state, prefix)
		for b_key, b_value in pairs(b) do
			b_value = as.value(b_value)
			local b_key_type = type(b_key)
			local b_key_is_str = b_key_type == "string"
			local dunder = b_key_is_str and b_key:match("^__")
			local is_opt = b_key_is_str and string.match(b_key, "^opt_")
			b_key = is_opt and (b_key:gsub("opt_", "")) or b_key
			b_key = (b_key_is_str and b_key:match("^%d+$") and tonumber(b_key)) or b_key

			local a_value = as.value(a[b_key])
			local current_prefix = prefix_msg(prefix, b_key)

			if (is.na(a_value) and is_opt) or dunder then
			elseif is.pure(b_value) then
				local ok, msg = is.pure(a_value, {
					dump = should_dump,
					assert = throw,
					prefix = current_prefix,
				})

				if not ok then
					if state then
						state[b_key] = err(a, b_key, a_value, msg or false)
					end
				elseif res then
					state[b_key] = {}
				end

				if ok then
					recurse(a_value, b_value, state and state[b_key], current_prefix)
				end
			elseif is.union(b_value) or is.pred(b_value) then
				---@cast b_value Union
				local ok, msg = b_value(a_value, {
					dump = should_dump,
					prefix = current_prefix,
					assert = throw,
				})

				if throw then
					error(msg)
				elseif state then
					if ok then
						state[b_key] = true
					else
						state[b_key] = err(a, b_key, a_value, msg or false)
					end
				end
			elseif is.object(b_value) then
				local ok, msg = is.object(a_value, {
					dump = should_dump,
					assert = throw,
					prefix = current_prefix,
				})

				if not ok then
					if state then
						state[b_key] = err(a, b_key, a_value, msg or false)
					end
				else
					ok, msg = lib.isa(a_value, b_value, {
						dump = should_dump,
						assert = throw,
						prefix = current_prefix,
					})

					if state then
						if not ok then
							state[b_key] = err(a, b_key, a_value, msg or false)
						else
							state[b_key] = a_value
						end
					end
				end
			elseif is.Callable(b_value) then
				local ok, err_msg = b_value(a_value, {
					dump = should_dump,
					prefix = current_prefix,
					assert = throw,
				})

				if state then
					if not ok then
						state[b_key] = err(a, b_key, a_value, (err_msg ~= nil and err_msg) or false)
					else
						state[b_key] = a_value
					end
				end
			elseif is.boolean(b_value) or is.number(b_value) or is.string(b_value) then
				local ok = a_value == b_value
				local msg = (
					not ok
					and (should_dump or throw)
					and lib.format("Expected literal value {%s}", tostring(b_value))
				)
				msg = msg and prefix_msg(current_prefix, b_key, msg)

				if not ok and throw then
					error(msg)
				elseif state then
					if ok then
						state[b_key] = true
					else
						state[b_key] = err(a, b_key, a_value, msg or false)
					end
				end
			elseif is.na(a_value) and not is.na(b_value) then
				error(prefix_msg(current_prefix, b_key, "Value is missing"))
			else
				local msg = "<spec>: Expected string|boolean|number|integer|callable|class|instance"
				msg = prefix_msg(current_prefix, b_key, msg)
				error(msg)
			end
		end
	end

	recurse(x, y, res, opts.prefix or "<root>")
	return res
end

---@generic T
---@class Predicate.class : class
---@field new fun(self: Predicate.class, fn: (fun(...): (string|Result)?), opts?: Predicate.opts): Predicate
Predicate = class("Predicate", nil, {
	static = { "predicate" },
})
lib.Predicate = Predicate
---@type table<string,Predicate>
lib.Predicate.predicate = {}
is.pred = is.Predicate
is.predicate = is.Predicate

---@class Predicate.opts
---@field safe? boolean
---@field message? string
---@field prefix? string

---@param fn GuardCallable
---@param opts? Predicate.opts
function Predicate:initialize(fn, opts)
	is.Callable(fn, { prefix = "fn", assert = true })
	opts = opts or {}
	self.fun = fn
	self.call = opts.safe and lib.rsafewrap(fn) or lib.rguardwrap(fn)
	self.safe = opts.safe
	self.message = opts.message or lib.paste0(tostring(fn), ": Assertion failure")
	self.prefix = opts.prefix
end

function Predicate:__call(...)
	return self.call(...)
end

function Predicate:assert(x)
	local prefix = self.prefix
	local message = self.message
	local res = self.call(x)

	if is.result(res) then
		if is.ok(res) then
			return x
		else
			local err = res.value --@as Error
			local msg = message or tostring(err)

			if prefix then
				error(lib.make_message(prefix, {
					message = msg,
				}))
			end
		end
	end
end

---@class Union.class : class
---@field new fun(self: Union, display: string?, signature: UnionSignature|UnionSignature[], throw?: boolean): Union
lib.Union = class("Union", nil, {
	static = {
		"all_of",
		"any_of",
		"pred",
		"validate_signature",
		"pred",
	},
})
Union = lib.Union
is.union = is.Union

---@param signature any[]
function Union.validate_signature(signature)
	signature = as.list(signature)
	for i = 1, #signature do
		local sig = signature[i]
		local ok = (
			(is.instance(sig) and (is.Union(sig) or is.Predicate(sig)))
			or is.object(sig)
			or is.Callable(sig)
			or (is.string(sig) and is[sig] ~= nil)
		)

		if not ok then
			errorf(
				"signature[%d]: Expected Union|Predicate|instance|class|Callable<fun(x: any, opts?: is.opts): boolean, string?>|is[<string>], got %s",
				i,
				sig
			)
		end
	end
end

---@param fn fun(x: any): string?
---@param opts? predicate.opts
---@return Predicate
function Union.pred(fn, opts)
	return Predicate:new(fn, opts)
end

function Union:initialize(display, signature, opts)
	assert(display, "No union string provided")
	assert(signature, "No signature provided")

	self.display = display
	self.signature = signature
	self.opts = opts

	Union.validate_signature(self.signature)
end

---@param x any
---@param opts? is.opts|Predicate.opts
---@return boolean, string?
function Union:__call(x, opts)
	opts = opts or self.opts
	x = as.value(x)

	if is.na(x) and opts.optional then
		return true
	end

	for i = 1, #self.signature do
		local sig = self.signature[i]
		if is.Union(sig) then
			---@cast sig Union
			local ok, _ = sig(x)
			if ok then
				return true
			end
		elseif is.Predicate(sig) then
			---@cast sig Predicate
			if sig(x, opts) then
				return true
			end
		elseif is.object(sig) then
			sig = is.instance(sig) and sig.__class or sig
			if is.instance(x) and lib.instanceof(x, sig) then
				return true
			end
		elseif is[sig] then
			if is[sig](x) then
				return true
			end
		elseif predicate.predicate[sig] then
			if predicate.predicate[sig](x) then
				return true
			end
		elseif is.Callable(sig) and sig(x) then
			return true
		end
	end

	if opts.assert or opts.dump or opts.prefix then
		local msg = lib.paste0("Expected ", self.display, sprintf(", got [%s] %s", type(x), x or "NIL"))
		msg = opts.prefix and (opts.prefix .. ": " .. msg) or msg

		if opts.assert then
			error(msg)
		else
			return false, msg
		end
	else
		return false
	end
end

---@param display? string|int
---@param signature UnionSignature|UnionSignature[]
---@param opts? Predicate.opts?
---@return Union
function Union.assert(display, signature, opts)
	opts = copy(opts)
	opts.assert = true
	return Union:new(display, signature, opts)
end

---@param display? string|int
---@param signature UnionSignature|UnionSignature[]
---@param opts? Predicate.opts?
---@return Union
function Union.any_of(display, signature, opts)
	opts = copy(opts or {})
	opts.assert = false
	return Union:new(display, signature, opts)
end

function Union.maybe(display, signature, opts)
	opts = copy(opts or {})
	opts.optional = true
	return Union:new(display, signature, opts)
end

--[[
Basic union type checking
--]]
--
lib.union = Union.any_of
lib.maybe = Union.maybe
lib.pred = Union.pred
lib.defguard = lib.mkguard

is.maybe = lib.defguard("maybe", function(x)
	return is.Union(x) and x.opts.optional
end)

is.union = is.Union

---@generic T
---@param fn fun(...): boolean, `T`|string?
---@return fun(...): Ok<`T`> | Err<CallError>
function lib.safe(fn)
	return function(...)
		local ok, msg = pcall(fn, ...)
		if not ok then
			msg = msg or ("Error from " .. tostring(fn))
			local err = CallError:new(msg, fn, { ... })
			return Err:new(err)
		else
			return Ok:new(msg)
		end
	end
end

---@class Specification.class : class
---@field new fun(self: Specification.class, name: string): Specification
Specification = class("Specification")

---@overload fun(x: any, opts?: is.opts): boolean, string
is.Specification = is.Specification
is.spec = is.Specification
is.Spec = is.spec

---@class Specification : Specification.class : instance
---@field name string
---@field spec table
---@field from_table nil
---@overload fun(x: table): table

function Specification:initialize(name)
	self.name = name
	self.spec = {}
end

---@param fn Union|Predicate|class|instance
---@param prefix? string
---@return boolean, string?
function Specification.is_valid_signature(fn, prefix)
	local valid = { Union, Predicate, is.class, is.instance }
	local check = lib.union("Union|Predicate|class|instance", valid)
	return check(fn, { dump = true, prefix = prefix })
end

---@param fn Union|Predicate|class|instance
---@param prefix? string
---@return Union|Predicate|class|instance
function Specification.assert_is_valid_signature(fn, prefix)
	local ok, msg = Specification.is_valid_signature(fn, prefix)
	if not ok then
		error(msg)
	else
		return fn
	end
end

---@param ks string|int
---@param fn Union|Predicate|class|instance
---@param prefix? string
function Specification:set(ks, fn, prefix)
	local ok, msg = Specification.is_valid_signature(fn)
	if not ok then
		local _ks = {}
		ks = as.list(ks)

		for _, k in ipairs(ks) do
			_ks[#_ks + 1] = tostring(k)
		end

		msg = table.concat(_ks, ".") .. ": " .. msg
		msg = prefix and (prefix .. ": " .. msg) or msg
		error(msg)
	end

	ks = as.list(ks)
	local x = self.spec

	for i = 1, #ks - 1 do
		x[ks[i]] = not is.pure(x[ks[i]]) and {} or x[ks[i]]
		x = x[ks[i]]
	end

	x[ks[#ks]] = fn
end

---@param x table
---@return table
function Specification:test(x)
	x = as.value(x)
	is.table(x, { assert = true, prefix = "x" })
	local res = lib.match(x, self.spec, { dump = true, prefix = self.name })
	---@cast res table
	return res
end

---@param x table
---@return table
function Specification:assert(x)
	x = as.value(x)
	is.table(x, { assert = true, prefix = "x" })
	local res = lib.match(x, self.spec, {
		dump = true,
		assert = true,
		prefix = self.name,
	})
	---@cast res table
	return res
end

---@param name string
---@param spec table
---@return Specification
function Specification.from_table(name, spec)
	local function fullkey(last_key, key)
		if is.int(key) then
			return lib.format("%s[%d]", last_key, key)
		else
			return lib.format("%s.%s", last_key, key)
		end
	end

	local function check_signature(key, value, last_key)
		local prefix = fullkey(last_key, key)
		local ok, msg = Specification.is_valid_signature(value, prefix)
		if not ok and msg then
			error(msg)
		end
	end

	local function recurse(got, last_key, res)
		for key, value in pairs(got) do
			if is.pure(value) then
				res[key] = res[key] or {}
				recurse(value, fullkey(last_key, key), res[key])
			else
				check_signature(key, value, last_key)
				res[key] = value
			end
		end
	end

	is.table(spec, { assert = true, prefix = "spec" })
	local res = Specification:new(name)
	recurse(spec, "<specification>", res.spec)
	res.spec = spec

	return res
end

---@param functions table<string, function>
function lib.from_table(functions)
	for key, value in pairs(functions) do
		package.user.lib[key] = value
	end
end

function lib.paste(sep, ...)
	sep = sep or " "
	local strs = { ... }
	return lib.join(strs, ...)
end

function lib.joinlines(...)
	return lib.join("\n", ...)
end

copy = copy
class = class
Spec = Specification
Specification = Specification
Predicate = Predicate
union = lib.union
maybe = lib.maybe
format = lib.format
substr = lib.substr
replace = lib.replace
Ok = Ok
Err = Err
rthread = lib.rthread
rpcall = lib.rpcall
rwrap = lib.rwrap
partial = lib.partial
predicate = lib.predicate
paste0 = lib.paste0
concat = lib.concat
joinlines = lib.joinlines

return lib
