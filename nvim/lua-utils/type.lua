require("lua-utils.definitions")

local copy = require("lua-utils.copy")
local lib = package.user.lib
local refself = lib.refself
local guards = lib.guards
local utils = {}

is = lib.is
as = lib.as

local Error, TypeError, CallError, UnwrapError
local Result, Ok, Err

---@alias likeFunction function|callable
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

---@class Result<T> : Result.class : instance<`T`>
---@field value? Error|`T`
---@field metadata? table
---@field err boolean
---@field ok boolean
---@field type "Err" | "Ok"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@class Ok<T> : Ok.class : Result
---@field value `T`
---@field err false
---@field ok true
---@field type "Ok"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@class Err : Err.class : Result
---@field value Error
---@field err true
---@field ok false
---@field type "Err"
---@field new nil
---@field initialize nil
---@field issubclass nil

---@generic T
---@overload fun(name: string, parent?: class, defaults?: table): class<`T`>
class = refself({})

-- local message = lib.message
local type_name = function(x)
	local x_type = type(x)
	if getmetatable(x) and x.__type and x.__name then
		return true, x.__type .. "." .. x.__name
	else
		return false, x_type
	end
end
local type_message = function(x, prefix, key)
	local is_type, x_type = type_name(x)
	local s = ((is_type and tostring(x)) or ((x_type ~= "string" and x_type ~= "number") and dump(x)) or tostring(x))
	local key_type = type(key)
	local msg = string.format("Got {%s} `%s`", x_type, s)
	local fmt

	if prefix then
		if key_type == "number" then
			fmt = (prefix .. string.format("[%d]", key))
		else
			fmt = (prefix .. "." .. tostring(key))
		end
	else
		if key_type == "number" then
			fmt = string.format("[%d]", key)
		else
			fmt = tostring(key)
		end
	end

	return fmt .. ": " .. msg
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
			local _msg = type_message(x, prefix, msg)
			if throw then
				error(_msg)
			end
			return false, _msg
		elseif should_dump then
			return false, type_message(x, prefix, msg)
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
		local msg = type_message(x, prefix, "Expected {instance.Error}")
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
		local msg = type_message(x, prefix, "Expected {instance.Error}")
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

is.callable = utils.defguard("callable", function(x)
	local x_type = type(x)
	if x_type == "function" then
		return
	elseif x_type == "table" then
		local mt = getmetatable(x)
		if mt and mt.__call then
			return
		end
	end

	return "Expected {table with __call metamethod | function}"
end)

is.class = utils.defguard("class", function(x)
	if not is.table(x) or x.__type ~= "class" then
		return 'Expected {table} with __type = "class"'
	end
end)

is.C = is.class

is.instance = utils.defguard("instance", function(x)
	if not is.table(x) or x.__type ~= "instance" then
		return 'Expected {table} with __type = "instance"'
	end
end)

is.I = is.instance

is.object = utils.defguard("object", function(x)
	if not is.class(x) and not is.instance(x) then
		return 'Expected {table} with __type = "class" | "instance"'
	end
end)

is.O = is.object

is.multimethod = utils.defguard("multimethod", function(x)
	if not is.instance(x) or x.__type ~= "multimethod" then
		return 'Expected {table} with __type = "class" | "instance" and __name = "multimethod"'
	end
end)

is.M = is.multimethod

is.template = utils.defguard("template", function(x)
	if not is.instance(x) or x.__type ~= "template" then
		return 'Expected {table} with __type = "class" | "instance" and __name = "template"'
	end
end)

is.T = is.template
is.F = is.callable

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

---@param child table
---@param parent table
---@param opts? is.opts
---@return boolean, string?
function utils.instanceof(child, parent, opts)
	child = as.value(child)
	parent = as.value(parent)

	assert(is.instance(child, { prefix = "<child>", assert = true }))
	assert(is.class(parent, { prefix = "<parent>", assert = true }))

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
		local msg = type_message(child, prefix, string.format("Expected instance of class %s", parent.__name))
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
		local msg = type_message(child, prefix, string.format("Expected subclass of class %s", parent.__name))
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
---@return likeFunction?
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
---@param make_guard? boolean
---@return class
function class.create_class(name, parent, make_guard)
	name = as.value(name)
	parent = as.value(parent)
	make_guard = as.value(make_guard)

	is.string(name, { prefix = "name", assert = true })
	is.class(parent, { prefix = "<parent>", assert = true, opt = true })

	local new = {}
	if parent then
		for key, value in pairs(parent) do
			new[key] = value
		end
	end

	new.issubclass = utils.issubclass
	new.__id = tostring(new)
	new.__name = name
	new.__class = parent
	new.__index = parent
	new.__type = "class"
	new.__tostring = new.__tostring
		or function(self)
			local attribs = {}
			for key, _ in pairs(self) do
				if not tostring(key):match("^__") then
					attribs[#attribs + 1] = key
				end
			end

			return string.format("%s.%s [%s] { %s }", self.__type, self.__name, self.__id, table.concat(attribs, ", "))
		end

	if parent then
		setmetatable(new, parent)
	else
		setmetatable(new, new)
	end

	if make_guard then
		utils.defguard(name, function(x, opts)
			return utils.instanceof(x, new, opts)
		end)
	end

	new.new = function(self, ...)
		local init = rawget(self, "initialize") or parent and parent.initialize
		if not init then
			error(string.format("%s: .initialize() is undefined", tostring(self)))
		end

		local obj = class.create_instance(self)
		init(obj, ...)

		local not_ok_msg = self.__validate and self.__validate(obj)
		if not_ok_msg then
			error(string.format("%s: Validation failure:\n%s", tostring(self), not_ok_msg))
		end

		return obj
	end

	return new
end

---@param cls class
---@return instance
function class.create_instance(cls)
	local new = setmetatable({}, cls)
	local inst_id = tostring(new)

	for key, value in pairs(cls) do
		new[key] = value
	end

	---@cast new instance
	new.__id = inst_id
	new.__type = "instance"
	new.__class = cls
	new.new = nil
	new.issubclass = nil
	new.instanceof = utils.instanceof

	return new
end

---@param name string
---@param parent? class
---@param defaults? table
---@return class
function class:__call(name, parent, defaults)
	local new = class.create_class(name, parent, true)
	for key, value in pairs(defaults or {}) do
		new[key] = value
	end
	return new
end

---@class Error
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
---@class Result.class : class
---@field new fun(self: Result, value?: Error | `T`, metadata?: table): Result<`T`>
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

---@generic T
---@class Ok.class : Result.class
---@field new fun(self: Ok.class, value?: `T`, metadata?: table): Ok<`T`>
Ok = class("Ok", Result)

function Ok:initialize(value, metadata)
	return Result.initialize(self, value, metadata)
end

---@class Err.class : Result.class
---@field new fun(self: Error, msg: string, metadata?: table): Err
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
	local throw = opts.assert
	local res = not throw and {} or nil
	local err = function(parent, key, value, msg)
		if type(msg) == "string" then
			return TypeError:new(msg, { key = key, value = value, msg = msg, parent = parent })
		else
			return false
		end
	end

	local function prefix_msg(prefix, key, msg, ...)
		if type(key) == "number" then
			key = prefix .. "." .. string.format("[%d]", key)
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
			::next::

			b_value = as.value(b_value)
			local b_key_type = type(b_key)
			local b_key_is_str = b_key_type == "string"

			if b_key_is_str and b_key:match("^__") then
				goto next
			end

			local is_opt = b_key_is_str and string.match(b_key, "^opt_")
			b_key = is_opt and (b_key:gsub("opt_", "")) or b_key
			b_key = (b_key_is_str and b_key:match("^%d+$") and tonumber(b_key)) or b_key
			local a_value = as.value(a[b_key])
			local current_prefix = prefix_msg(prefix, b_key)

			if a_value == nil and is_opt then
				goto next
			end

			if is.pure_table(a_value) and is.pure_table(b_value) then
				if res then
					state[b_key] = {}
					state = state[b_key]
				end
				recurse(a_value, b_value, state, current_prefix)
			elseif is.object(b_value) then
				local ok, msg = is.object(a_value, {
					dump = true,
					assert = throw,
					prefix = current_prefix,
				})

				if not ok then
					if state then
						state[b_key] = err(a, b_key, a_value, msg or false)
					end
				else
					ok, msg = utils.instanceof(a_value, b_value, {
						dump = true,
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
			elseif is.callable(b_value) then
				is.callable(b_value, {
					prefix = current_prefix,
					assert = true,
				})

				local ok, err_msg = b_value(a_value, {
					dump = true,
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
				local msg = not ok and string.format("Expected literal value {%s}", tostring(b_value))

				if msg and throw then
					error(msg)
				elseif state then
					if ok then
						state[b_key] = true
					else
						state[b_key] = err(a, b_key, a_value, msg or false)
					end
				end
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
---@param force? boolean
---@return table
function as.list(x, force)
	if force or not is.list(x) then
		return { x }
	else
		return x
	end
end

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

---@param sig string|likeFunction|class
---@return function
local function normalize(sig)
	if is.string(sig) then
		return is[sig]
	elseif is.callable(sig) then
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
		error(string.format("signature[%d]: Expected string|callable|class, got {%s}", dump(sig)))
	end
end

--[[
Basic union type checking
--]]

function utils.all_of(x, ...)
	local signature = { ... }
	for i = 1, #signature do
		local sig = normalize(signature[i])
		if not sig(x) then
			return false
		end
	end
	return true
end

function utils.any_of(x, ...)
	local signature = { ... }
	for i = 1, #signature do
		local sig = normalize(signature[i])
		if sig(x) then
			return true
		end
	end
	return false
end

---@param display string
---@param ... string|function|callable|class
---@return fun(x: any, opts?: is.opts): boolean, string?
function utils.union(display, ...)
	local signature = { ... }
	return function(x, opts)
		opts = opts or {}
		local ok

		if not (opts.optional or opts.opt) then
			ok = utils.any_of(x, unpack(signature))
		else
			ok = utils.any_of(x, is.na, unpack(signature))
		end

		if ok then
			return true
		elseif not opts.dump and not opts.assert then
			return false
		end

		local prefix = opts.prefix
		local throw = opts.assert
		local msg = type_message(x, prefix, string.format("Expected %s", display))

		if throw then
			error(msg)
		else
			return false, msg
		end
	end
end

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
---@type {[string]: (fun(x: any, opts?: is.opts): boolean, string?)}
setmetatable(lib.isa, {
	__index = function(_, name)
		return function(x, opts)
			opts = copy.copy(opts or {})
			opts.assert = true
			opts.dump = true
			return is[name](x, opts)
		end
	end,
})

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
