require 'lua-utils.definitions'


local lib = package.user.lib
local copy = lib.copy
local refself = lib.refself
local guards = lib.guards
local utils = {}
local base_class = { __type = "class", __name = "base" }


is = lib.is
as = lib.as

local Error, TypeError, CallError, UnwrapError
local Result, Ok, Err

---@alias guard1 fun(x: any, opts?: is.opts): boolean, string?
---@alias guard2 fun(x: any, y: any, opts?: is.opts): boolean, string?
---@alias guard guard1 | guard2

---@class TypeError : Error
---@class CallError : Error
---@class UnwrapError : Error

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
---@field instanceof fun(self: instance<`T`>, other: class, opts?: is.opts): boolean, string?

---@class class<T>
---@field new fun(self: `T`, ...): instance<`T`>
---@field initialize fun(self: `T`, ...)
---@field __name string?
---@field __type "class"
---@field __class? class
---@field __tostring function
---@field __index? class
---@field __id string
---@field issubclass fun(self: class<`T`>, other: class, opts?: is.opts): boolean, string?

---@class Result.class<T,E> : class
---@field new fun(self: Result<`T`,`E`>, value?: `E`|`T`, metadata?: table): Result<`T`,`E`>

---@class Result<T,E> : Result.class<`T`,`E`> : instance
---@field value? `E`|`T`
---@field metadata? table
---@field err boolean
---@field ok boolean
---@field type "Err" | "Ok"
---@field new nil
---@field initialize nil
---@field issubclass nil
---@field unwrap nil
---@field thread nil

---@class Ok.class<T> : Result.class<`T`, nil>
---@field new fun(self: Ok.class<`T`>, value?: `T`, metadata?: table): Ok<`T`>

---@class Ok<T> : Ok.class<`T`> : instance
---@field value `T`
---@field err false
---@field ok true
---@field type "Ok"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@class Err.class<E> : Result.class<nil,`E`>
---@field new fun(self: Error, msg: string, metadata?: table): Err<`E`>

---@class Err<E> : Err.class<`E`> : instance
---@field value Error
---@field err true
---@field ok false
---@field type "Err"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@generic T
---@overload fun(name: string, parent?: class, opts?: class.opts): class<`T`>
class = refself({})

local function expected_type_msg(obj, prefix, msg)
	local got = string.format("%s. Got [%s] %s", msg, type(obj), dump(obj))
	if prefix then
		return prefix .. ": " .. got
	else
		return got
	end
end

---@class is.opts
---@field assert? boolean
---@field dump? boolean
---@field prefix? string
---@return fun(x: any, opts?: is.opts): boolean, string?
function utils.defguard(key, f)
	local function fn(x, opts)
		x = as.value(x)
		opts = opts or {}
		local opt = opts.optional or opts["?"] or opts.opt
		local should_dump = opts.dump
		local prefix = opts.prefix
		local throw = opts.assert

		if opt and x == nil then
			return true
		end

		local msg = f(x)
		if not msg then
			return true
		elseif throw or should_dump then
			local _msg = expected_type_msg(x, prefix, msg)
			if throw then
				error(_msg)
			end
			return false, _msg
		elseif should_dump then
			return false, expected_type_msg(x, prefix, msg)
		else
			return false
		end
	end

	rawset(is, key, fn)
	guards[key] = fn

	return fn
end

---@param x any
---@param opts? is.opts
---@return boolean, string?
function is.error(x, opts)
	opts = opts or {}
	local throw = opts.assert
	local prefix = opts.prefix
	local should_dump = opts.dump

	if not is.instance(x) then
		local msg = expected_type_msg(x, prefix, "Expected {instance.Error}")
		if throw then
			error(msg)
		elseif should_dump then
			return false, msg
		else
			return false
		end
	elseif x.__name == "Error" then
		return true
	end

	x = as.value(x)
	local cls = x.__class

	while cls do
		if cls.__name == "Error" then
			return true
		else
			cls = cls.__class
		end
	end

	if should_dump or throw then
		local msg = expected_type_msg(x, prefix, "Expected {instance.Error}")
		if throw then
			error(msg)
		end
		return false, msg
	end

	return false
end

---@param tp string
---@return fun(x: any, opts?: is.opts): boolean, string?
local function mkguard(tp)
	return utils.defguard(tp, function(x)
		local x_tp = type(x)
		if x_tp ~= tp then
			return string.format("Expected {%s}", tp)
		end
	end)
end

is.boolean = mkguard("boolean")
is.string = mkguard("string")
is.number = mkguard("number")
is.userdata = mkguard("userdata")
is["function"] = mkguard("function")
is.userdata = mkguard("userdata")
is.thread = mkguard("thread")
is.table = mkguard("table")
is.bool = is.boolean
is.num = is.number
is.str = is.string
is.fun = is["function"]
is.seq = sequence
is["nil"] = is.na

is.pure_table = utils.defguard("pure_table", function(x)
	local x_type = type(x)
	local mt = x_type == "table" and getmetatable(x)

	if x_type ~= "table" or mt then
		return "Expected {table} without a metatable"
	end
end)

is.ptable = is.pure_table

is.list = utils.defguard("list", function(x)
	local x_type = type(x)
	local mt = x_type == "table" and getmetatable(x)

	if x_type ~= "table" or mt then
		return "Expected {list} without a metatable"
	elseif size(x) ~= #x then
		return "Expected {list} got {dict}"
	end
end)

is.dict = utils.defguard("dict", function(x)
	local x_type = type(x)
	local mt = x_type == "table" and getmetatable(x)

	if x_type ~= "table" or mt then
		return "Expected {dict} without a metatable"
	elseif size(x) == #x then
		return "Expected {dict} got {list}"
	end
end)

is.Callable = utils.defguard("Callable", function(x)
	local x_type = type(x)
	if x_type == "function" then
		return
	elseif x_type == "table" then
		local mt = getmetatable(x)
		if mt and mt.__call then
			return
		else
			return "Expected {table.__call|function}"
		end
	else
		return "Expected {table.__call|function}"
	end
end)

is.na = utils.defguard("na", function(x)
	if as.value(x) ~= nil then
		return "Expected nil value"
	end
end)

is.defined = utils.defguard("defined", function(x)
	if as.value(x) == nil then
		return "Expected value, got nil"
	end
end)

is.undefined = is.na
is.undef = is.na
is.def = is.defined

is.callable = utils.defguard("callable", function(x)
	if type(x) ~= "table" then
		return "Expected table.__call"
	else
		return is.Callable(x)
	end
end)

is.class = utils.defguard("class", function(x)
	if not is.table(x) or x.__type ~= "class" then
		return "Expected {class}"
	end
end)

is.C = is.class

is.instance = utils.defguard("instance", function(x)
	if not is.table(x) or x.__type ~= "instance" then
		return "Expected {instance}"
	end
end)

is.I = is.instance

is.object = utils.defguard("object", function(x)
	if not is.class(x) and not is.instance(x) then
		return "Expected {class|instance}"
	end
end)

is.O = is.object

is.multimethod = utils.defguard("multimethod", function(x)
	if not is.instance(x) or x.__type ~= "multimethod" then
		return "Expected {multimethod}"
	end
end)

is.M = is.multimethod

is.template = utils.defguard("template", function(x)
	if not is.instance(x) or x.__type ~= "template" then
		return "Expected {template}"
	end
end)

is.T = is.template
is.F = is.Callable

is.integer = utils.defguard("integer", function(x)
	if tonumber(x) and tostring(x):match("^%d+$") then
		return
	else
		return "Expected {integer}"
	end
end)

is.int = is.integer

is.result = utils.defguard("result", function(x)
	if not utils.instanceof(x, Result) then
		return "Expected instance.Result | instance.Ok | instance.Err"
	end
end)

is.res = is.result

is.ok = utils.defguard("ok", function(x)
	if not is.Result(x, Result) and not x.ok then
		return "Expected instance.Ok"
	end
end)

is.err = utils.defguard("err", function(x)
	if not utils.instanceof(x, Result) or x.ok then
		return "Expected instance.Err"
	end
end)

---@param child instance
---@param parent class
---@param opts? is.opts
---@return boolean, string?
function utils.instanceof(child, parent, opts)
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
		local msg = expected_type_msg(child, prefix, string.format("Expected instance.%s", parent.__name))
		if throw then
			error(msg)
		end
		return false, msg
	else
		return false
	end
end

---@param child table
---@param parent table
---@param opts? is.opts
---@return boolean, string?
function utils.issubclass(child, parent, opts)
	child = as.value(child)
	parent = as.value(parent)
	assert(is.class(child, { prefix = "<child>", assert = true }))

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
		local msg = expected_type_msg(child, prefix, string.format("Expected subclass of class.%s", parent.__name))
		if throw then
			error(msg)
		end
		return false, msg
	else
		return false
	end
end

---@param cls object
---@return class
function class.get_class(cls)
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
function class.get_method(cls, name)
	cls = as.value(cls)
	local method = class.get(cls, name)
	if method == nil then
		return
	end

	local prefix = string.format("%s.%s", cls.__name, tostring(name))
	is.callable(method, { prefix = prefix, assert = true })

	return method
end

---@param cls object
---@param name string
---@param ... any
---@return any
function class.get_method_and_apply(cls, name, ...)
	local fn = class.get_method(cls, name)
	if fn then
		return fn(...)
	end
end

---@param cls object
---@param names_only? boolean
---@return (class[]|string)?
function class.get_parents(cls, names_only)
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
function class.get_attributes(cls)
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
function class.get_name(cls)
	cls = as.value(cls)
	assert(is.object(cls, { prefix = "<cls>", assert = true }))
	return cls.__name
end

---@param cls object
---@return table
function class.get_meta_attributes(cls)
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
function class.create_class(name, parent, static)
	name = as.value(name)
	parent = as.value(parent)
	parent = parent or base_class

	is.string(name, { prefix = "name", assert = true })
	is.class(parent, { prefix = "<parent>", assert = true })

	local new = {}
	new.__id = tostring(new):gsub("^table: ", "")
	new.issubclass = utils.issubclass
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

			return string.format("%s.%s [%s] { %s }", self.__type, self.__name, self.__id, table.concat(attribs, ", "))
		end

	is[name] = utils.defguard(name, function(x)
		if not is.instance(x) or not utils.instanceof(x, new) then
			return "Expected instance of class." .. new.__name
		end
	end)

	for key, value in pairs(parent) do
		if is.na(new[key]) then
			new[key] = value
		end
	end

	new.new = function(self, ...)
		local init = rawget(self, "initialize") or parent and parent.initialize
		if not init then
			error(string.format("%s: .initialize() is undefined", tostring(self)))
		end

		local obj = class.create_instance(self, static)
		init(obj, ...)

		local not_ok_msg = self.__validate and self.__validate(obj)
		if not_ok_msg then
			error(string.format("%s: Validation failure:\n%s", tostring(self), not_ok_msg))
		end

		return obj
	end

	return setmetatable(new, parent)
end

---@param cls class
---@param ignore? table<string,boolean>
---@return instance
function class.create_instance(cls, ignore)
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
	new.instanceof = utils.instanceof

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

	local new = class.create_class(name, parent, ignore)

	if opts.include then
		for key, value in pairs(opts.include) do
			new[key] = value
		end
	end

	return new
end

---@class Error : Error.class : instance
---@field msg? any
---@field metadata? table
---@field args any[]
---@field new fun(self: Error, name: string, msg: string, metadata?: table, ...: any): Error

---@class Error.class : class
---@field new fun(self: Error.class, name: string, msg?: string, metadata?: table): Error
Error = class("Error")

function Error:initialize(name, msg, metadata, ...)
	self.name = name
	msg = as.value(msg)
	metadata = as.value(metadata)
	self.msg = msg
	self.metadata = metadata
	self.args = { ... }
end

---Raise error
function Error:throw()
	error(self:__tostring(self))
end

---Throw error if condition is falsy
---@param cond boolean
---@return boolean
function Error:throw_unless(cond)
	if not cond then
		return cond
	else
		error(tostring(self))
	end
end

---Throw error if condition is truthy
---@param cond boolean
---@return boolean
function Error:throw_when(cond)
	if cond then
		return cond
	else
		error(tostring(self))
	end
end

function Error:__tostring()
	local parents = class.get_parents(self, true)
	local name = table.concat(parents, ".")
	local mt = self.metadata
	local args = self.args

	if mt and args then
		return string.format("%s: %s\nmetadata: %s\n\nargs: %s", name, self.msg or "error!", dump(mt), dump(args))
	elseif args then
		return string.format("%s: %s\nargs: %s", name, self.msg or "error!", dump(args))
	elseif mt then
		return string.format("%s: %s\nmetadata: %s", name, self.msg or "error!", dump(mt))
	end

	return string.format("%s: error!", name)
end

---@class TypeError.class : Error.class
---@field new fun(self: Error.class, msg?: string, metadata?: table): TypeError
TypeError = class("TypeError", Error)

---@class CallError.class : Error.class
---@field new fun(self: Error.class, msg?: string, metadata?: table): CallError
CallError = class("CallError", Error)

---@class UnwrapError.class : Error.class
---@field new fun(self: Error.class, msg?: string, metadata?: table): UnwrapError
UnwrapError = class("UnwrapError", Error)

---@generic T
Result = class("Result")

function Result:initialize(value, metadata)
	value = as.value(value)
	metadata = as.value(metadata)
	self.err = is.error(value)
	self.type = self.err and "Err" or "Ok"
	self.ok = self.type ~= "Err"
	self.value = value
	self.metadata = metadata
end

function Result:unwrap()
	if self.err then
		---@type Error
		self.value:throw()
	else
		---@type Ok
		return self.value
	end
end

function Result:__tostring()
	return string.format("Result.%s { value = %s, metadata = %s }", self.type, dump(self.value), dump(self.metadata))
end

Ok = class("Ok", Result)

function Ok:initialize(value, metadata)
	return Result.initialize(self, value, metadata)
end

Err = class("Err", Result)

function Err:initialize(msg, metadata)
	return Result.initialize(self, UnwrapError(msg), metadata)
end

---@param fn function
---@param ... any
---@return Ok|Err
function utils.rpcall(fn, ...)
	local ok, msg = pcall(fn, ...)
	local mt = { fun = fn, args = { ... } }

	if not ok then
		return Result:new(CallError(msg, mt))
	else
		return Result:new(msg, mt)
	end
end

---@generic T
---@param fn fun(...): `T`
---@return ResultCallable<`T`>
function utils.rwrap(fn)
	if not is.ResultCallable(fn) then
		return ResultCallable:new(fn)
	else
		return fn
	end
end

---@param x any
---@param funs (fun(x: any): Result)[]
---@param throw_on_err? boolean
---@return Ok|Err
function utils.rthread(x, funs, throw_on_err)
	local last = x
	if is.result(last) then
		last = last:unwrap()
	end

	for i = 1, #funs do
		local f = funs[i]
		is.callable(f, { prefix = string.format("<functions>[%d]", i), assert = true })

		local res = utils.rpcall(f, last)
		if is.err(res) then
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
	elseif is.result(last) then
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
function utils.match(x, y, opts)
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
			key = prefix .. string.format("[%d]", key)
		else
			key = prefix .. "." .. key
		end

		if not msg then
			return string.format("%s", key)
		else
			msg = string.format(msg, ...)
			return string.format("%s: %s", key, msg)
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
			elseif is.pure_table(b_value) then
				local ok, msg = is.pure_table(a_value, {
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
			elseif is.Union(b_value) or is.UnionPredicate(b_value) then
				---@cast b_value Union
				local ok, msg = b_value(a_value, {
          dump = should_dump,
          prefix = current_prefix,
          assert = throw
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
					ok, msg = utils.instanceof(a_value, b_value, {
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
					and string.format("Expected literal value {%s}", tostring(b_value))
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

---@param x any
---@return number?
function as.number(x)
	return tonumber(x)
end

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

---@param x any
---@return boolean
function as.boolean(x)
	if x then
		return true
	else
		return false
	end
end

---@param x any
---@return string
function as.string(x)
	if type(x) == "table" and x.__tostring then
		return tostring(x)
	else
		return dump(x)
	end
end

---@param sig string|Callable|class
---@param i int
---@return function
local function normalize(sig, i)
	if is.string(sig) then
		return is[sig]
	elseif is.Callable(sig) then
		---@type function
		return sig
	elseif is.class(sig) then
		return function(obj)
			if is.instance(obj) then
				return utils.instanceof(obj, sig)
			elseif is.class(obj) then
				return utils.issubclass(obj, sig)
			else
				return false
			end
		end
	else
		error(string.format("signature[%d]: Expected string|callable|class, got {%s}", i, dump(sig)))
	end
end

---@alias UnionSignature class|instance|Union|UnionPredicate|Callable|string|fun(x: any): string?

---@class Union.class : class
---@field new fun(self: Union, display: string?, signature: UnionSignature|UnionSignature[], throw?: boolean): Union
local Union = class("Union", nil, {
	static = {
		"Predicate",
		"all_of",
		"any_of",
		"pred",
	},
})

---@class UnionPredicate.opts
---@field assert? boolean
---@field prefix? string

---@class UnionPredicate.class : class
---@field new fun(self: UnionPredicate.class, fn: Callable): UnionPredicate
local UnionPredicate = class("UnionPredicate")

---@class UnionPredicate : UnionPredicate.class : instance
---@field assert? boolean
---@field opts UnionPredicate.opts
---@field new nil
---@overload fun(x: any): boolean, string?

---@overload fun(x: any, opts?: is.opts): boolean, string?
is.UnionPredicate = is.UnionPredicate

---@class Union : Union.class : instance
---@field signature UnionSignature|UnionSignature[]
---@field display string
---@field opts UnionPredicate.opts | is.opts
---@field any_of nil
---@field all_of nil
---@field validate_signature nil
---@field predicate fun(x: any): string?
---@overload fun(x: any, opts?: is.opts): boolean, string?

---@overload fun(x: any, opts?: is.opts): boolean, string
is.Union = is.Union

function UnionPredicate:initialize(fn)
	is.Callable(fn, { prefix = "fn", assert = true })
	self.predicate = fn
end

---@param x any
---@param opts? UnionPredicate.opts
---@return boolean, string?
function UnionPredicate:run(x, opts)
	opts = opts or {}
	local msg = self.predicate(x)

	if not msg then
		return true
	end

	msg = msg or "Predicate failure"
	if opts.prefix then
		msg = opts.prefix .. ": " .. msg
	end

	if opts.assert then
		error(msg)
	else
		return false, msg
	end
end

UnionPredicate.__call = UnionPredicate.run

function UnionPredicate:assert(x, opts)
	return self:run(x, opts)
end

---@param signature any[]
function Union.validate_signature(signature)
	signature = as.list(signature)
	for i = 1, #signature do
		local sig = signature[i]
		local ok = (
			is.Union(sig)
			or is.UnionPredicate(sig)
			or is.object(sig)
			or is.Callable(sig)
			or (is.string(sig) and is[sig])
		)

		if not ok then
			errorf(
				"signature[%d]: Expected Union|UnionPredicate|instance|class|Callable<fun(x: any, opts?: is.opts): boolean, string?>|is[<string>], got %s",
				i,
				sig
			)
		end
	end
end

---@param fn fun(x: any): string?
---@return UnionPredicate
function Union.pred(fn)
	return UnionPredicate:new(fn)
end

function Union:initialize(display, signature, opts)
	self.display = display
	self.signature = signature
	self.opts = opts
	Union.validate_signature(self.signature)
end

---@param x any
---@param opts? is.opts|UnionPredicate.opts
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
		elseif is.UnionPredicate(sig) then --[[@cast sig UnionPredicate]]
			if sig:run(x, opts) then
				return true
			end
		elseif is.object(sig) then
			sig = is.instance(sig) and sig.__class or sig
			if is.instance(x) and utils.instanceof(x, sig) then
				return true
			end
		elseif is[sig] and is[sig](x) then
			return true
		elseif is.Callable(sig) and sig(x) then
			return true
		end
	end

	if opts.assert or opts.dump or opts.prefix then
		local msg = "Expected " .. self.display .. sprintf(", got [%s] %s", type(x), x or "NIL")
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
---@param opts? UnionPredicate.opts?
---@return Union
function Union.assert(display, signature, opts)
	opts = copy(opts)
	opts.assert = true
	return Union:new(display, signature, opts)
end

---@param display? string|int
---@param signature UnionSignature|UnionSignature[]
---@param opts? UnionPredicate.opts?
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
utils.union = Union.any_of
utils.maybe = Union.maybe
utils.pred = Union.pred

is.maybe = utils.defguard("maybe", function(x)
	return is.Union(x) and x.opts.optional
end)

is.union = is.Union

---@param display string
---@return fun(...): (fun(x: any, opts?: is.opts): boolean, string?)
function utils.maybe(display, ...)
	return function(...)
		local signature = { ... }
		return function(x, opts)
			opts = opts or {}
			opts.optional = true
			local check = is.union(display)(unpack(signature))
			return check(x, opts)
		end
	end
end

---[[Basically is.*(*, {assert = true})]]
---@type {[string]: fun(x: any, opts?: is.opts)}
setmetatable(lib.isa, {
	__index = function(_, name)
		return function(x, opts)
			opts = copy.copy(opts or {})
			opts.assert = true
			opts.dump = true
			is[name](x, opts)
		end
	end,
})

---@class SafeCallable.class<T> : class
---@field new fun(self, fn: (fun(...): `T`), prefix?: string): SafeCallable<`T`>
SafeCallable = class("SafeCallable")

---@class SafeCallable<T> : SafeCallable.class<`T`> : instance
---@field call fun(...): `T`
---@field safe fun(...): boolean, `T`|string
---@field __call fun(...): boolean, `T`|string

function SafeCallable:initialize(fn, prefix)
	self.call = fn
	self.safe = function(...)
		local ok, msg = pcall(self.call, ...)
		if ok then
			return true, msg
		elseif msg and prefix then
			msg = type(msg) == "string" and (prefix .. ": " .. msg)
			return false, msg
		elseif msg then
			return false, msg
		elseif prefix then
			return false, string.format("%s: %s() threw an error", prefix, self.call)
		else
			return false, msg
		end
	end
end

function SafeCallable:__call(...)
	return self.safe(...)
end

---@type fun(x: any, opts?: is.opts): boolean, string?
is.SafeCallable = is.SafeCallable

---@class ResultCallable.class<T,E> : class
---@field new fun(self, fn: (fun(...): `T`|`E`), prefix?: string): ResultCallable<`T`,`E`>
ResultCallable = class("ResultCallable")

---@class ResultCallable<T,E> : ResultCallable.class<`T`,`E`> : instance
---@field call fun(...): `T`|`E`
---@field safe fun(...): Ok<`T`> | Err<`E`>
---@field __call fun(...): Ok<`T`> | Err<`E`>

function ResultCallable:initialize(fn, prefix)
	self.call = fn
	self.safe = function(...)
		local res = Result:new(pcall(self.call, ...))
		---@cast res Result
		if res.ok then
			return res
		elseif res.metadata and is.table(res.metadata) then
			res.metadata.prefix = prefix
		elseif res.metadata and is.string(res.metadata) and prefix then
			res.metadata = prefix .. ": " .. res.metadata
		end
		return res
	end
end

function ResultCallable:__call(...)
	return self.safe(...)
end

---@type fun(x: any, opts?: is.opts): boolean, string?
is.ResultCallable = is.ResultCallable

---@generic T
---@param fn fun(...): T
---@return SafeCallable<`T`>
function utils.safe(fn)
	if is.SafeCallable(fn) then
		return fn
	else
		return SafeCallable:new(fn)
	end
end

---@generic T
---@param fn fun(...): T
---@return ResultCallable<`T`>
function utils.rsafe(fn)
	if is.ResultCallable(fn) then
		return fn
	else
		return ResultCallable:new(fn)
	end
end

---@class Spec.class : class
---@field new fun(self: Spec.class, name: string): Spec
local Spec = class("Spec")

---@overload fun(x: any, opts?: is.opts): boolean, string
is.Spec = is.Spec

---@class Spec : Spec.class : instance
---@field name string
---@field spec table
---@field from_table nil
---@overload fun(x: table): table

function Spec:initialize(name)
	self.name = name
	self.spec = {}
end

---@param fn Union|UnionPredicate|class|instance
---@param prefix? string
---@return boolean, string?
function Spec.is_valid_signature(fn, prefix)
	local valid = { Union, UnionPredicate, is.class, is.instance }
	local check = utils.union("Union|UnionPredicate|class|instance", valid)
	return check(fn, { dump = true, prefix = prefix })
end

---@param fn Union|UnionPredicate|class|instance
---@param prefix? string
---@return Union|UnionPredicate|class|instance
function Spec.assert_is_valid_signature(fn, prefix)
	local ok, msg = Spec.is_valid_signature(fn, prefix)
	if not ok then
		error(msg)
	else
		return fn
	end
end

---@param ks string|int
---@param fn Union|UnionPredicate|class|instance
---@param prefix? string
function Spec:set(ks, fn, prefix)
	local ok, msg = Spec.is_valid_signature(fn)
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
		x[ks[i]] = not is.pure_table(x[ks[i]]) and {} or x[ks[i]]
		x = x[ks[i]]
	end

	x[ks[#ks]] = fn
end

---@param x table
---@return table
function Spec:test(x)
	x = as.value(x)
	is.table(x, { assert = true, prefix = "x" })
	local res = utils.match(x, self.spec, { dump = true, prefix = self.name })
	---@cast res table
	return res
end

---@param x table
---@return table
function Spec:assert(x)
	x = as.value(x)
	is.table(x, { assert = true, prefix = "x" })
	local res = utils.match(x, self.spec, { 
    dump = true,
    assert = true,
    prefix = self.name,
  })
	---@cast res table
	return res
end

---@param name string
---@param spec table
---@return Spec
function Spec.from_table(name, spec)
  local function fullkey(last_key, key)
    if is.int(key) then
      return string.format("%s[%d]", last_key, key)
    else
      return string.format("%s.%s", last_key, key)
    end
  end
	local function check_signature(key, value, last_key)
    local prefix = fullkey(last_key, key)
    local ok, msg = Spec.is_valid_signature(value, prefix)
    if not ok and msg then
      error(msg)
    end
	end
  local function recurse(got, last_key, res)
    for key, value in pairs(got) do
      if is.pure_table(value) then
        res[key] = res[key] or {}
        recurse(value, fullkey(last_key, key), res[key])
      else
        check_signature(key, value, last_key)
        res[key] = value
      end
    end
  end

	is.table(spec, { assert = true, prefix = "spec" })
	local res = Spec:new(name)
  recurse(spec, '<specification>', res.spec)
  res.spec = spec

  return res
end

utils.as = as
utils.is = is
utils.isa = lib.isa
utils.TypeError = TypeError
utils.CallError = CallError
utils.UnwrapError = UnwrapError
utils.Result = Result
utils.Err = Err
utils.Ok = Ok
utils.Error = Error
utils.callable = callable
utils.sequence = sequence
utils.bless = bless
utils.pack = pack
utils.length = length
utils.size = size
utils.rtostring = rtostring
utils.class = class
utils.pp = pp
utils.dump = dump
utils.printf = printf
utils.sprintf = sprintf
utils.errorf = errorf
utils.SafeCallable = SafeCallable
utils.ResultCallable = ResultCallable
utils.Union = Union
utils.UnionPredicate = UnionPredicate
utils.Spec = Spec

package.user.lib.Spec = Spec
package.user.lib.TypeError = TypeError
package.user.lib.CallError = CallError
package.user.lib.UnwrapError = UnwrapError
package.user.lib.Result = Result
package.user.lib.Err = Err
package.user.lib.Ok = Ok
package.user.lib.Error = Error
package.user.lib.class = class
package.user.lib.instanceof = utils.instanceof
package.user.lib.issubclass = utils.issubclass
package.user.lib.union = utils.union
package.user.lib.maybe = utils.maybe
package.user.lib.type = utils
package.user.lib.defguard = utils.defguard
package.user.lib.rwrap = utils.rwrap
package.user.lib.rthread = utils.rthread
package.user.lib.rpcall = utils.rpcall
package.user.lib.ResultCallable = ResultCallable
package.user.lib.SafeCallable = SafeCallable
package.user.lib.safe = utils.safe
package.user.lib.rsafe = utils.rsafe
package.user.lib.Union = Union
package.user.lib.UnionPredicate = UnionPredicate
package.user.lib.result = {
	Result = Result,
	Ok = Ok,
	Err = Err,
	UnwrapError = UnwrapError,
	pcall = utils.rpcall,
	wrap = utils.rwrap,
	thread = utils.rthread,
}

global({
	TypeError = TypeError,
	CallError = CallError,
	UnwrapError = UnwrapError,
	Result = Result,
	Err = Err,
	Ok = Ok,
	Error = Error,
	class = class,
	instanceof = utils.instanceof,
	issubclass = utils.issubclass,
	union = utils.union,
	maybe = utils.maybe,
	defguard = utils.defguard,
	rwrap = utils.rwrap,
	rthread = utils.rthread,
	rpcall = utils.rpcall,
	ResultCallable = ResultCallable,
	SafeCallable = SafeCallable,
	safe = utils.safe,
	rsafe = utils.rsafe,
	is = is,
	as = as,
	Union = Union,
	UnionPredicate = UnionPredicate,
	Spec = Spec,
})

local spec = Spec.from_table('NeovimConfig', {
  a = utils.pred(function(x) if not is.int(x) then return 'Expected int' end end),
  b = utils.pred(function(x) if not is.int(x) then return 'Expected int' end end)
})

-- spec:assert {a={1}}

unfreeze_globals()
