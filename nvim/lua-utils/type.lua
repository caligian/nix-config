local inspect = require 'lua-utils.inspect'

---@alias guard1 fun(x: any, opts?: is.opts): boolean, string?
---@alias guard2 fun(x: any, y: any, opts?: is.opts): boolean, string?
---@alias guard guard1 | guard2

---@class is
---@type {[string]: guard1 | guard2}
local is = { assert = {}, optional = {}, dump = {}, }
local as = {}
local class = {}
local utils = { is = is, as = as, class = class, }
local Result, Ok, Err
local Error, CallError, UnwrapError, TypeError
is.opt = is.optional

setmetatable(is, is)
setmetatable(is.assert, is.assert)
setmetatable(is.dump, is.dump)
setmetatable(is.optional, is.optional)
setmetatable(class, class)
setmetatable(as, as)

package = package or {}
package.user = package.user or {}
package.user.NIL = setmetatable({}, { __tostring = function(_) return 'nil' end })
package.user.lib = package.user.lib or {}
package.user.lib.NIL = package.user.NIL
package.user.lib.types = package.user.lib.types or {}
package.user.lib.builtin_types = package.user.lib.builtin_types or {
  'boolean',
  'string',
  'number',
  'function',
  'userdata',
  'thread',
  'table',
  'nil',
}
package.user.lib.dont_subclass = package.user.lib.dont_subclass or {
  union = true,
  multimethod = true,
  pcall = true,
  template = true,
}
package.user.lib.is = package.user.lib.is or is

local types = package.user.lib.types
NIL = package.user.NIL

---@param x any
---@return string
function dump(x)
  local tp = type(x)
  if tp == 'table' then
    local mt = getmetatable(x)
    if mt and mt.__tostring then
      return tostring(x)
    else
      return inspect(x, { indent = '  ' })
    end
  else
    return tostring(x)
  end
end

---@param x any
---@return boolean
function is_nil(x)
  return x == NIL or x == nil
end

---@param x any
---@return any
function as_value(x)
  if x == NIL or x == nil then
    return nil
  else
    return x
  end
end

---@param x any
---@return string
function pp(x)
  local s = dump(x)
  print(s)
  return s
end

---@param x any
---@return any
function rtostring(x)
  if type(x) ~= "table" then
    return tostring(x)
  elseif x.__tostring then
    return x:__tostring()
  end

  local res = {}
  for key, value in pairs(x) do
    if type(value) == 'table' and value.__tostring then
      res[key] = value:__tostring()
    else
      res[key] = package.user.lib.rtostring(value)
    end
  end

  return dump(res)
end

---@param ... any
---@return any[]
function pack(...)
  local args = { ... }
  local nargs = select('#', ...)
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
function sprintf(msg, ...)
  local args = pack(...)
  local res = {}

  for i = 1, #args do
    res[#res + 1] = dump(args[i])
  end

  return string.format(msg, unpack(res))
end

---@param msg string
---@param ... any
---@return string
function printf(msg, ...)
  local args = pack(...)
  local res = {}

  for i = 1, #args do
    res[#res + 1] = dump(args[i])
  end

  local s = string.format(msg, unpack(res))
  print(s)

  return s
end

---@param msg string
---@param ... any
function errorf(msg, ...)
  error(sprintf(msg, ...))
end

---@param x table|string
---@return integer
function size(x)
  if type(x) == 'string' then
    return #x
  end

  local size = 0
  for _, _ in pairs(x) do size = size + 1 end
  return size
end

---@param x table|string
---@return integer
function length(x)
  return #x
end

---@param x? table
---@param metatable? table
---@return table
function bless(x, metatable)
  x = x or {}
  metatable = metatable or x
  return setmetatable(x, metatable)
end

---@param x? any
---@return boolean
function callable(x)
  local x_tp = type(x)
  if x_tp == 'function' then
    return true
  elseif x_tp == 'table' and x.__call then
    return true
  else
    return false
  end
end

---@param x any
---@return boolean
function sequence(x)
  local x_tp = type(x)
  if x_tp == 'table' then
    return size(x) == length(x)
  elseif x_tp == 'string' then
    return true
  else
    return false
  end
end

local function obj_message(x, prefix, msg, ...)
  local x_type = type(x)
  local is_type = false

  if getmetatable(x) and x.__type and x.__name then
    is_type = true
    x_type = x.__type .. '.' .. x.__name
  end

  local s = (
    (is_type and tostring(x)) or
    ((x_type ~= 'string' and x_type ~= 'number') and dump(x)) or
    tostring(x)
  )
  msg = msg .. "\n" .. string.format("Got {%s}: %s", x_type, s)

  if prefix then
    return string.format('%s: %s', prefix, string.format(msg, ...))
  else
    return string.format(msg, ...)
  end
end

---@class is.opts
---@field assert? boolean
---@field dump? boolean
---@field prefix? string
function is:new(key, f)
  local function fn(x, opts)
    x = as_value(x)
    opts = opts or {}
    local opt = opts.optional or opts['?'] or opts.opt
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
      local _msg = obj_message(x, prefix, msg)
      if throw then error(_msg) end
      return false, _msg
    elseif should_dump then
      return false, obj_message(x, prefix, msg)
    else
      return false
    end
  end

  rawset(self, key, fn)
  types[key] = fn
  return fn
end

function is:new_class(cls)
  cls = as_value(cls)
  assert(is.class(cls, { prefix = '<cls>', assert = true }))

  return is:new(
    cls.__name,
    function(x, opts) return is.instanceof(x, cls, opts) end
  )
end

function is.error(x, opts)
  opts = opts or {}
  local throw = opts.assert
  local prefix = opts.prefix
  local should_dump = opts.dump

  if not is.instance(x) then
    local msg = obj_message(x, prefix, 'Expected {instance.Error}')
    if throw then
      error(msg)
    elseif should_dump then
      return false, msg
    else
      return false
    end
  elseif x.__name == 'Error' then
    return true
  end

  x = as_value(x)
  local cls = x.__class

  while cls do
    if cls.__name == 'Error' then
      return true
    else
      cls = cls.__class
    end
  end

  if should_dump or throw then
    local msg = obj_message(x, prefix, 'Expected {instance.Error}')
    if throw then error(msg) end
    return false, msg
  end

  return false
end

for _, tp in ipairs(package.user.lib.builtin_types) do
  if tp == 'nil' then
    is:new('nil', function(x)
      if not is_nil(x) then
        return string.format('Expected {nil}')
      end
    end)
  else
    is:new(tp, function(x)
      local x_tp = type(x)
      if x_tp ~= tp then return string.format('Expected {%s}', tp) end
    end)
  end
end

is:new('pure_table', function(x)
  local x_type = type(x)
  local mt = x_type == 'table' and getmetatable(x)

  if x_type ~= 'table' or mt then
    return 'Expected {table} without a metatable'
  end
end)

is:new('list', function(x)
  local x_type = type(x)
  local mt = x_type == 'table' and getmetatable(x)

  if x_type ~= 'table' or mt then
    return 'Expected {list} without a metatable'
  elseif size(x) ~= #x then
    return 'Expected {list} got {dict}'
  end
end)

is:new('dict', function(x)
  local x_type = type(x)
  local mt = x_type == 'table' and getmetatable(x)

  if x_type ~= 'table' or mt then
    return 'Expected {dict} without a metatable'
  elseif size(x) == #x then
    return 'Expected {dict} got {list}'
  end
end)

is:new('callable', function(x)
  local x_type = type(x)
  local mt = x_type == 'table' and getmetatable(x)

  if x_type ~= 'table' or not mt or not mt.__call then
    return 'Expected {table} with __call metamethod'
  end
end)

is:new('class', function(x)
  if not is.table(x) or x.__type ~= 'class' then
    return 'Expected {table} with __type = "class"'
  end
end)

is:new('instance', function(x)
  if not is.table(x) or x.__type ~= 'instance' then
    return 'Expected {table} with __type = "instance"'
  end
end)

is:new('object', function(x)
  if not is.class(x) and not is.instance(x) then
    return 'Expected {table} with __type = "class" | "instance"'
  end
end)

is:new('multimethod', function(x)
  if not is.instance(x) or x.__type ~= 'multimethod' then
    return 'Expected {table} with __type = "class" | "instance" and __name = "multimethod"'
  end
end)

is:new('template', function(x)
  if not is.instance(x) or x.__type ~= 'template' then
    return 'Expected {table} with __type = "class" | "instance" and __name = "template"'
  end
end)

is:new('like_function', function(x)
  if not is['function'](x) and not is.callable(x) then
    return 'Expected {function|callable}'
  end
end)

is:new('integer', function(x)
  if not is.number(x) and not tostring(x):match('^%d+$') then
    return 'Expected {integer}'
  end
end)

function is.instanceof(child, parent, opts)
  child = as_value(child)
  parent = as_value(parent)

  assert(is.instance(child, { prefix = '<child>', assert = true, }))
  assert(is.class(parent, { prefix = '<parent>', assert = true, }))

  if child.__class == parent then
    return true
  end

  local cls = child.__class
  while cls do
    if cls == parent then return true end
    cls = cls.__class
  end

  opts = opts or {}
  local prefix = opts.prefix
  local should_dump = opts.dump
  local throw = opts.assert

  if throw or should_dump then
    local msg = obj_message(
      child,
      prefix,
      string.format('Expected instance of class %s', parent.__name)
    )
    if throw then error(msg) end
    return false, msg
  else
    return false
  end
end

function is.subclass(child, parent, opts)
  child = as_value(child)
  parent = as_value(parent)

  assert(is.class(child, { prefix = '<child>', assert = true }))

  if child.__class == parent then
    return true
  end

  local cls = child.__class
  while cls do
    if cls == parent then return true end
    cls = cls.__class
  end

  opts = opts or {}
  local prefix = opts.prefix
  local should_dump = opts.dump
  local throw = opts.assert

  if throw or should_dump then
    local msg = obj_message(child, prefix, 'Expected subclass of class %s', parent.__name)
    if throw then error(msg) end
    return false, msg
  else
    return false
  end
end

function class.get_class(cls)
  cls = as_value(cls)
  assert(is.object(cls, { prefix = '<cls>', assert = true, }))

  if is.instance(cls) then
    return cls.__class
  else
    return cls
  end
end

function class.get(cls, name)
  cls = as_value(cls)
  assert(is.class(cls, { prefix = '<cls>', assert = true, }))
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

function class.get_method(cls, name)
  cls = as_value(cls)
  local method = class.get(cls, name)
  if method == nil then
    return
  end

  local prefix = string.format('%s.%s', cls.__name, tostring(name))
  is.like_function(method, { prefix = prefix, assert = true, })

  return method
end

function class.get_method_and_apply(cls, name, ...)
  local fn = class.get_method(cls, name)
  if fn then
    return fn(...)
  end
end

function class.get_parents(cls, names_only)
  cls = as_value(cls)
  local parents = {}
  local parent = rawget(cls, '__class')

  while parent do
    parents[#parents + 1] = parent
    parent = rawget(parent, '__class')
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

function class.get_attributes(cls)
  cls = as_value(cls)
  assert(is.object(cls, { prefix = '<cls>', assert = true, }))
  local res = {}

  for key, value in pairs(cls) do
    if not key:match('^__') then res[key] = value end
  end

  return res
end

function class.get_name(cls)
  cls = as_value(cls)
  assert(is.object(cls, { prefix = '<cls>', assert = true, }))
  return cls.__name
end

function class.get_meta_attributes(cls)
  cls = as_value(cls)
  assert(is.object(cls, { prefix = '<cls>', assert = true, }))
  local res = {}

  for key, value in pairs(cls) do
    if key:match('^__') then res[key] = value end
  end

  return res
end

function class.create_class(name, parent, make_guard)
  name = as_value(name)
  parent = as_value(parent)
  make_guard = as_value(make_guard)

  is.string(name, { prefix = 'name', assert = true })
  is.class(parent, { prefix = '<parent>', assert = true, opt = true })

  local new = {}
  if parent then
    for key, value in pairs(parent) do
      new[key] = value
    end
  end

  new.issubclass = is.subclass
  new.__id = tostring(new)
  new.__name = name
  new.__class = parent
  new.__index = parent
  new.__type = 'class'
  new.__tostring = new.__tostring or function(self)
    local attribs = {}
    for key, _ in pairs(self) do
      if not tostring(key):match('^__') then
        attribs[#attribs + 1] = key
      end
    end

    return string.format(
      '%s.%s [%s] { %s }',
      self.__type,
      self.__name,
      self.__id,
      table.concat(attribs, ", ")
    )
  end

  if parent then
    setmetatable(new, parent)
  else
    setmetatable(new, new)
  end

  if make_guard then
    is:new_class(new)
  end

  new.new = function(self, ...)
    local init = rawget(self, 'initialize') or parent and parent.initialize
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

function class.create_instance(cls)
  local new = class.create_class(cls.__name, cls)
  new.__type = 'instance'
  new.__class = cls
  new.issubclass = nil
  new.instanceof = is.instanceof
  setmetatable(new, cls)
  return new
end

function class:__call(name, parent, defaults)
  local new = class.create_class(name, parent, true)
  for key, value in pairs(defaults or {}) do new[key] = value end
  return new
end

Error = class 'Error'

function Error:initialize(msg, metadata, ...)
  msg = as_value(msg)
  metadata = as_value(metadata)
  self.msg = msg
  self.metadata = metadata
  self.args = { ... }
end

function Error:throw()
  error(self:__tostring(self))
end

function Error:throw_unless(cond)
  if not cond then
    return cond
  else
    error(tostring(self))
  end
end

function Error:throw_when(cond)
  if cond then
    return cond
  else
    error(tostring(self))
  end
end

function Error:__tostring()
  local parents = class.get_parents(self, true)
  local name = table.concat(parents, '.')
  local mt = self.metatable
  local args = self.args
  local msg

  if mt and args then
    msg = string.format(
      '%s: %s\nmetadata: %s\n\nargs: %s',
      self.name,
      self.msg or 'error!',
      dump(self.metadata),
      dump(self.args)
    )
  elseif args then
    msg = string.format(
      '%s: %s\nargs: %s',
      name,
      self.msg or 'error!',
      dump(self.args)
    )
  elseif mt then
    msg = string.format(
      '%s: %s\nmetadata: %s',
      name,
      self.msg or 'error!',
      dump(self.metadata)
    )
  end

  error(msg)
end

TypeError = class('TypeError', Error)
CallError = class('CallError', Error)
UnwrapError = class('UnwrapError', Error)

Error.TypeError = TypeError
Error.CallError = CallError
Error.UnwrapError = UnwrapError

function Error.pcall(fn, ...)
  local args = { ... }
  local ok, msg = pcall(fn, ...)

  if not ok then
    return CallError(msg, { fun = fn, args = args })
  else
    return msg
  end
end

Result = class 'Result'
Result.UnwrapError = UnwrapError

function Result:initialize(value, metadata)
  value = as_value(value)
  metadata = as_value(metadata)
  self.err = is.error(value)
  self.type = self.err and 'Err' or 'Ok'
  self.ok = self.type ~= 'Err'
  self.value = value
  self.metadata = metadata
end

function Result:unwrap()
  if self.err then
    self.value:throw()
  else
    return self.value
  end
end

function Result.pcall(fn, ...)
  local ok, msg = pcall(fn, ...)
  local mt = { fun = fn, args = { ... } }

  if not ok then
    return Result:new(CallError(msg, mt))
  else
    return Result:new(msg, mt)
  end
end

function Result:__tostring()
  return string.format(
    "Result.%s { value = %s, metadata = %s }",
    self.type,
    dump(self.value),
    dump(self.metadata)
  )
end

Ok = class('Ok', Result)
function Ok:initialize(value, metadata)
  return Result.initialize(self, value, metadata)
end

Err = class('Err', Result)
function Err:initialize(msg, metadata)
  return Result.initialize(self, UnwrapError(msg), metadata)
end

Result.Ok = Ok
Result.Err = Err

function Result.thread(x, funs, throw_on_err)
  opts = opts or {}
  local last = x

  for i = 1, #funs do
    local f = funs[i]
    is.like_function(f, { prefix = string.format('<functions>[%d]', i), assert = true })

    local res = Result.pcall(f, last)
    if is.Err(res) then
      res.metadata = res.metadata or {}
      res.metadata.index = i
      res.metadata.fun = f
      res.metadata.last_value = last

      if throw_on_err then
        res:unwrap()
      else
        return res
      end
    else
      last = last:unwrap()
    end
  end

  if is.error(last) then
    return Result.Err(last)
  elseif is.Result(last) then
    return last
  else
    return Result(last)
  end
end

is:new('Result', function(x)
  if not is.instanceof(x, Result) then
    return 'Expected instance.Result | instance.Ok | instance.Err'
  end
end)

is:new('Ok', function(x)
  if not is.Result(x, Result) and not x.ok then
    return 'Expected instance.Ok'
  end
end)

is:new('Err', function(x)
  if not is.instanceof(x, Result) then
    return 'Expected instance.Err'
  end
end)


---@param x table
---@param y table
---@param opts? is.opts
---@return table?
function is.match(x, y, opts)
  x = as_value(x)
  y = as_value(y)

  is.table(x, { assert = true, prefix = '<x>' })
  is.table(y, { assert = true, prefix = '<y>' })

  opts = opts or {}
  local throw = opts.assert
  local res = not throw and {} or nil
  local err = function(parent, key, value, msg)
    if type(msg) == 'string' then
      return TypeError:new(msg, { key = key, value = value, msg = msg, parent = parent })
    else
      return false
    end
  end

  local function prefix_msg(prefix, key, msg, ...)
    if type(key) == 'number' then
      key = prefix .. '.' .. string.format('[%d]', key)
    else
      key = prefix .. '.' .. key
    end

    if not msg then
      return string.format('%s', key)
    else
      msg = string.format(msg, ...)
      return string.format('%s: %s', key, msg)
    end
  end

  local function recurse(a, b, state, prefix)
    for b_key, b_value in pairs(b) do
      ::next::

      b_value = as_value(b_value)
      local b_key_type = type(b_key)
      local b_key_is_str = b_key_type == 'string'

      if b_key_is_str and b_key:match('^__') then
        goto next
      end

      local is_opt = b_key_is_str and string.match(b_key, '^opt_')
      b_key = is_opt and (b_key:gsub('opt_', '')) or b_key
      b_key = (b_key_is_str and b_key:match('^%d+$') and tonumber(b_key)) or b_key
      local a_value = as_value(a[b_key])
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
          ok, msg = is.instanceof(a_value, b_value, {
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
      elseif is.like_function(b_value) then
        is.like_function(b_value, {
          prefix = current_prefix,
          assert = true
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
        local msg = '<spec>: Expected string|boolean|number|integer|like_function|class|instance'
        msg = prefix_msg(current_prefix, b_key, msg)
        error(msg)
      end
    end
  end

  recurse(x, y, res, opts.prefix or '<root>')
  return res
end

function as.list(x, force)
  if force or not is.list(x) then
    return { x }
  else
    return x
  end
end

function as.value(x)
  if is_nil(x) then
    return nil
  else
    return x
  end
end

function as.integer(x)
  if type(x) == 'string' and string.match(x, '^%d+$') then
    return tonumber
  end
end

function as.number(x)
  return tonumber(x)
end

function as.fun(x, ...)
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

function as.boolean(x)
  if x then
    return true
  else
    return false
  end
end

function as.string(x)
  if type(x) == 'table' and x.__tostring then
    return tostring(x)
  else
    return dump(x)
  end
end

local function normalize(sig)
  if is.string(sig) then
    return is[sig]
  elseif is.like_function(sig) then
    return sig
  elseif is.class(sig) then
    return function(obj)
      if is.instance(obj) then
        return is.instanceof(obj, sig)
      elseif is.class(obj) then
        return is.subclass(obj, sig)
      else
        return false
      end
    end
  else
    error(string.format("signature[%d]: Expected string|like_function|class, got {%s}", dump(sig)))
  end
end

function is.all_of(x, ...)
  local signature = { ... }
  for i = 1, #signature do
    local sig = normalize(signature[i])
    if not sig(x) then return false end
  end
  return true
end

function is.any_of(x, ...)
  local signature = { ... }
  for i = 1, #signature do
    local sig = normalize(signature[i])
    if sig(x) then return true end
  end
  return false
end

---@param display string
---@return fun(...): (fun(x: any, opts?: is.opts): boolean, string?)
function is.union(display)
  return function(...)
    local signature = { ... }
    return function(x, opts)
      opts = opts or {}
      local ok

      if not (opts.optional or opts.opt) then
        ok = is.any_of(x, unpack(signature))
      else
        ok = is.any_of(x, is.na, unpack(signature))
      end

      if ok then
        return true
      elseif not opts.dump and not opts.assert then
        return false
      end

      local prefix = opts.prefix
      local throw = opts.assert
      local msg = obj_message(x, prefix, 'Expected %s', display)

      if throw then
        error(msg)
      else
        return false, msg
      end
    end
  end
end

---@param display string
---@return fun(...): (fun(x: any, opts?: is.opts): boolean, string?)
function is.maybe(display)
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

function is.assert:__index(tp)
  return function(x, opts)
    return is[tp](x, {
      prefix = opts.prefix,
      assert = true,
      dump = true,
    })
  end
end

function is.dump:__index(tp)
  return function(x, opts)
    return is[tp](x, {
      prefix = opts.prefix,
      assert = opts.assert,
      dump = true
    })
  end
end

function is.optional:__index(tp)
  return function(x, opts)
    return is[tp](x, {
      prefix = opts.prefix,
      assert = opts.assert,
      dump = opts.dump,
      optional = true
    })
  end
end

package.user.lib.callable = callable
package.user.lib.sequence = sequence
package.user.lib.bless = bless
package.user.lib.rtostring = rtostring
package.user.lib.dump = dump
package.user.lib.NIL = NIL
package.user.lib.pp = pp
package.user.lib.as_value = as_value
package.user.lib.is_nil = is_nil
package.user.lib.printf = printf
package.user.lib.sprintf = sprintf
package.user.lib.size = size
package.user.lib.length = length
package.user.lib.pack = pack
package.user.lib.errorf = errorf

is.na = is['nil']
is.fun = is['function']
is.n = is.number
is.i = is.integer
is.s = is.string
is.b = is.boolean
is.f = is.fun
is.t = is.table
is.u = is.userdata
is.h = is.thread
is.C = is.subclass
is.I = is.instanceof
is.c = is.class
is.ic = is.instance
is.o = is.object
is.F = is.like_function

as['function'] = as.fun
as.n = as.number
as.i = as.integer
as.f = as.f
as.b = as.boolean
as.bool = as.boolean
as.s = as.string
as.str = as.string

utils.bless = bless
utils.callable = callable
utils.sequence = sequence
utils.dump = dump
utils.pp = pp
utils.as_value = package.user.lib.as_value
utils.is_nil = package.user.lib.is_nil
utils.rtostring = rtostring
utils.is_result = is.Result
utils.is_ok = is.Ok
utils.is_err = is.Err
utils.is_table = is.table
utils.is_string = is.string
utils.is_number = is.number
utils.is_userdata = is.userdata
utils.is_function = is.fun
utils.is_boolean = is.boolean
utils.is_thread = is.thread
utils.is_list = is.list
utils.is_dict = is.dict
utils.is_pure_table = is.pure_table
utils.is_class = is.class
utils.is_instance = is.instance
utils.is_error = is.error
utils.is_object = is.object
utils.as_number = as.number
utils.as_integer = as.integer
utils.as_function = as.fun
utils.as_boolean = as.boolean
utils.as_string = as.string
utils.any_of = is.any_of
utils.all_of = is.all_of
utils.union = is.union
utils.maybe = is.maybe
utils.pack = pack
utils.sprintf = sprintf
utils.printf = printf
utils.errorf = errorf
utils.union = is.union
utils.maybe = is.maybe
utils.NIL = package.user.NIL
utils.Error = Error
utils.CallError = Error.CallError
utils.TypeError = Error.TypeError
utils.UnwrapError = Error.UnwrapError
utils.as = as
utils.Result = Result
utils.Ok = Ok
utils.Err = Err

function utils:import()
  _G.bless = bless
  _G.callable = callable
  _G.sequence = sequence
  _G.dump = dump
  _G.pp = pp
  _G.errorf = errorf
  _G.rtostring = rtostring
  _G.is_result = is.Result
  _G.is_ok = is.Ok
  _G.is_err = is.Err
  _G.is_table = is.table
  _G.is_string = is.string
  _G.is_number = is.number
  _G.is_userdata = is.userdata
  _G.is_function = is.fun
  _G.is_boolean = is.boolean
  _G.is_thread = is.thread
  _G.is_list = is.list
  _G.is_dict = is.dict
  _G.is_pure_table = is.pure_table
  _G.is_class = is.class
  _G.is_instance = is.instance
  _G.is_error = is.error
  _G.is_object = is.object
  _G.as_number = as.number
  _G.as_integer = as.integer
  _G.as_function = as.fun
  _G.as_boolean = as.boolean
  _G.as_string = as.string
  _G.any_of = is.any_of
  _G.all_of = is.all_of
  _G.union = is.union
  _G.maybe = is.maybe
  _G.pack = pack
  _G.sprintf = sprintf
  _G.printf = printf
  _G.errorf = errorf
  _G.union = is.union
  _G.maybe = is.maybe
  _G.as = as
  _G.Error = Error
  _G.CallError = Error.CallError
  _G.TypeError = Error.TypeError
  _G.UnwrapError = Error.UnwrapError
  _G.NIL = package.user.lib.NIL
  _G.Result = Result
  _G.Ok = Result.Ok
  _G.Err = Result.Err
  _G.TypeError = TypeError
  _G.CallError = CallError
  _G.UnwrapError = UnwrapError
  _G.is = is
  _G.class = class
  _G.inspect = inspect
end

return utils
