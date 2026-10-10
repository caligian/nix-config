if package.user and package.user.loaded then
  return package.user
end

local inspect = require('inspect')
package.user = {
  NIL = setmetatable({}, { __tostring = function(_) return 'nil' end }),
  ---Exhaustive list of all possible metamethods.
  ---TODO: Restrict only to luajit (I have to think about this in the future)
  ---@type {[string]: string}
  operators = {
    len = '__len',
    concat = '__concat',
    pow = '__pow',
    mod = '__mod',
    pairs = '__pairs',
    ipairs = '__ipairs',
    add = '__add',
    sub = '__sub',
    mul = '__mul',
    div = '__div',
    unm = '__unm',
    call = '__call',
    index = '__index',
    newindex = '__newindex',
    lt = '__lt',
    le = '__le',
    eq = '__eq',
    tostring = '__tostring',
    metatable = '__metatable',
    mode = '__mode',
    gc = '__gc',
    __len = '__len',
    __concat = '__concat',
    __pow = '__pow',
    __mod = '__mod',
    __pairs = '__pairs',
    __ipairs = '__ipairs',
    __add = '__add',
    __sub = '__sub',
    __mul = '__mul',
    __div = '__div',
    __unm = '__unm',
    __call = '__call',
    __index = '__index',
    __newindex = '__newindex',
    __lt = '__lt',
    __le = '__le',
    __eq = '__eq',
    __tostring = '__tostring',
    __metatable = '__metatable',
    __mode = '__mode',
    __gc = '__gc',
    ['+'] = '__add',
    ['-'] = '__sub',
    ['*'] = '__mul',
    ['/'] = '__div',
    ['-1'] = '__unm',
    ['()'] = '__call',
    ['[]'] = '__index',
    ['[]='] = '__newindex',
    ['<'] = '__lt',
    ['<='] = '__le',
    ['=='] = '__eq',
    ['..'] = '__concat',
  },
  lib = {
    ---@param prefix string?
    ---@param msg string
    ---@param ... any
    ---@return string
    message = function(prefix, msg, ...)
      local prefix_type = type(prefix)
      prefix = prefix_type == 'number' and string.format('[%d]', prefix) or prefix

      if not prefix then
        return string.format(msg, ...)
      else
        return string.format('%s: %s', prefix, string.format(msg, ...))
      end
    end,

    ---@param name string
    ---@param value any
    ---@param force? boolean
    ---@return boolean
    gset = function(name, value, force)
      if force or not _G[name] then
        _G[name] = value
      elseif _G[name] then
        return false
      end
      return true
    end,

    ---@param name string
    ---@param value any
    gsetf = function(name, value)
      package.user.lib.gset(name, value, true)
    end,

    ---@param x any
    ---@return any
    as_value = function(x)
      if x == package.user.NIL then
        return nil
      else
        return x
      end
    end,

    ---@param x any
    ---@return any[]
    as_list = function(x, force)
      if force then
        return { x }
      elseif type(x) == 'table' then
        return x
      else
        return { x }
      end
    end,

    ---Iterate over all entries. If the callback returns `false`,
    ---iteration stops early (like `break`).
    ---@param x table
    ---@param fn fun(key: string|integer, value: any): boolean?
    ---@return table  -- returns x for chaining
    each = function(x, fn)
      for key, value in pairs(x) do
        if fn(key, value) == false then
          break
        end
      end
      return x
    end,

    ---Return true if any entry satisfies the predicate.
    ---Short-circuits on the first match.
    ---@param x table
    ---@param fn fun(key: string|integer, value: any): boolean
    ---@return boolean
    any = function(x, fn)
      for key, value in pairs(x) do
        if fn(key, value) then
          return true
        end
      end
      return false
    end,

    ---Return true if every entry satisfies the predicate.
    ---Short-circuits on the first failure. Vacuously true for empty tables.
    ---@param x table
    ---@param fn fun(key: string|integer, value: any): boolean
    ---@return boolean
    all = function(x, fn)
      for key, value in pairs(x) do
        if not fn(key, value) then
          return false
        end
      end
      return true
    end,

    ---@param x any
    ---@return boolean
    is_nil = function(x)
      return x == package.user.NIL or x == nil
    end,

    ---@param tbl table
    ---@return  {[1]: (string|integer)[], [2]: any}[]
    items = function(tbl)
      local res = {}
      for key, value in pairs(tbl) do
        res[#res + 1] = { key, value }
      end
      return res
    end,

    ---@param tbl table
    ---@return any[]
    values = function(tbl)
      local res = {}
      for _, value in pairs(tbl) do
        res[#res + 1] = value
      end
      return res
    end,

    ---@param tbl table
    ---@return (string|integer)[]
    keys = function(tbl)
      local res = {}
      for key, _ in pairs(tbl) do
        res[#res + 1] = key
      end
      return res
    end,

    ---@param x table
    ---@param name string
    ---@param value any
    ---@return table
    on = function(x, name, value)
      local mt = getmetatable(x) or x
      local ops = package.user.operators

      assert(ops[name], 'Invalid operator string provided: ' .. tostring(name))
      mt[ops[name]] = value

      return setmetatable(x, mt)
    end,

    ---If metatable is not set or __index is undefined, reference to self
    ---@param x table
    ---@return table?
    refself = function(x)
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
    end,

    get_mt = getmetatable,
    set_mt = setmetatable,

    ---@param x table
    ---@param ks (string|integer)[]
    ---@return any?
    mt_get = function(x, ks)
      local mt = getmetatable(x)
      if not mt then
        return
      end

      return package.user.lib.get(mt, ks)
    end,

    ---@param x table
    ---@param ks (string|integer)[]
    ---@param value any
    ---@return boolean
    mt_set = function(x, ks, value)
      local mt = getmetatable(x)
      if not mt then
        return false
      else
        return package.user.lib.set(mt, ks, value)
      end
    end,

    ---Force set a value
    ---@param x table
    ---@param ks (string|integer)[]
    ---@param value any
    setf = function(x, ks, value)
      ks = type(ks) ~= 'table' and { ks } or ks
      local l = #ks
      local dst = x

      for i = 1, l - 1 do
        local k = ks[i]
        dst[k] = {}
        dst = dst[k]
      end

      dst[ks[l]] = value
    end,

    ---Update package.user table
    ---@param x table
    ---@param ks (string|integer)[]
    ---@param value any
    ---@return boolean
    set = function(x, ks, value)
      ks = type(ks) ~= 'table' and { ks } or ks
      local l = #ks
      local dst = x

      for i = 1, l - 1 do
        local k = ks[i]
        local v = dst[k]

        if type(v) ~= 'table' then
          return false
        else
          dst = v
        end
      end

      dst[ks[l]] = value
      return true
    end,

    ---Check if a key exists
    ---@param x table
    ---@param ks (string|integer)[]
    ---@return boolean
    has = function(x, ks)
      ks = type(ks) ~= 'table' and { ks } or ks
      local l = #ks
      local dst = x

      for i = 1, l - 1 do
        local k = ks[i]
        local v = dst[k]

        if type(v) ~= 'table' then
          return false
        else
          dst = v
        end
      end

      return dst[ks[l]] ~= nil
    end,

    ---Get value from package.user
    ---@param x table
    ---@param ks (string|integer)[]
    ---@return any?
    get = function(x, ks)
      ks = type(ks) ~= 'table' and { ks } or ks
      local l = #ks
      local dst = x

      for i = 1, l - 1 do
        local k = ks[i]
        local v = dst[k]

        if type(v) ~= 'table' then
          return
        else
          dst = v
        end
      end

      return dst[ks[l]]
    end,

    ---Unset key from package.user.table
    ---@param x table
    ---@param ks (string|integer)[]
    ---@return any?
    unset = function(x, ks)
      ks = type(ks) ~= 'table' and { ks } or ks
      local l = #ks
      local dst = x

      for i = 1, l - 1 do
        local k = ks[i]
        local v = dst[k]

        if type(v) ~= 'table' then
          return
        else
          dst = v
        end
      end

      local v = dst[ks[l]]
      dst[ks[l]] = nil

      return v
    end,

    ---@param x table
    ---@param fn fun(key: integer|string, value: any): any
    ---@return table
    map = function(x, fn)
      local res = {}
      for key, value in pairs(x) do
        res[key] = fn(key, value)
      end
      return res
    end,

    ---@param x table
    ---@param fn fun(key: integer|string, value: any): boolean
    ---@return table
    filter = function(x, fn)
      local res = {}
      for key, value in pairs(x) do
        if fn(key, value) then
          res[key] = value
        end
      end
      return res
    end,

    ---@param x table
    ---@param init any
    ---@param fn fun(key: string|integer, acc: any, value: any): any
    ---@return any
    reduce = function(x, init, fn)
      local res = init
      for key, value in pairs(x) do
        res = fn(key, res, value)
      end
      return res
    end,

    ---@param filename string
    ---@param mode? string
    ---@param fn fun(fh: file*): any
    ---@return boolean, any
    open_and_then = function(filename, mode, fn)
      local ok
      local fh, msg = io.open(filename, mode or 'r')

      if not fh then
        return false, msg
      end

      ok, msg = pcall(fn, fh)
      fh:close()

      return ok, msg
    end,

    ---@param filename string
    ---@param mode? string
    ---@return boolean, string?
    bslurp = function(filename, mode)
      mode = mode or 'r'
      mode = not string.match(mode, 'b') and (mode .. 'b') or mode
      return package.user.lib.slurp(filename, mode)
    end,

    ---@param filename string
    ---@param mode? string
    ---@param contents string|string[]
    ---@return boolean, string?
    bspit = function(filename, mode, contents)
      mode = mode or 'w'
      mode = not string.match(mode, 'b') and (mode .. 'b') or mode
      return package.user.lib.spit(filename, mode, contents)
    end,

    ---@param filename string
    ---@param mode? string
    ---@return boolean, string?
    slurp = function(filename, mode)
      mode = mode or 'r'
      return package.user.lib.open_and_then(filename, mode, function(fh)
        return fh:read('*a')
      end)
    end,

    ---@param filename string
    ---@param mode? string
    ---@param contents string|string[]
    ---@return boolean, string?
    spit = function(filename, mode, contents)
      contents = type(contents) == 'table' and table.concat(contents, "\n") or contents
      mode = mode or 'w'
      assert(type(contents) == 'string', 'contents= is not of type string')

      return package.user.lib.open_and_then(filename, mode, function(fh)
        local ok, err = fh:write(contents)
        if not ok then
          error(err)
        end
      end)
    end,

    inspect = inspect,
  },

  ---Contains all user configuration
  config = {
    workspace = {
      check_depth = 5,
      marker = { '.PROJECT' },
    }
  },

  ---Contains user state
  state = {},

  ---Builtin types
  ---@type string[]
  builtin_types = {
    'boolean',
    'string',
    'number',
    'function',
    'userdata',
    'thread',
    'table',
    'nil',
  },

  ---User defined types
  ---@type {[string]: boolean}
  types = {
    list         = true,
    dict         = true,
    boolean      = true,
    string       = true,
    number       = true,
    ['function'] = true,
    userdata     = true,
    thread       = true,
    table        = true,
    ['nil']      = true,
    class        = true,
    instance     = true,
  },

  ---@type {[string]: function}
  guards = {},

  ---Contains all classes made by the user
  ---@type {[string]: class}
  classes = {},

  ---Force set a value
  ---@param ks (string|integer)[]
  ---@param value any
  setf = function(ks, value)
    ks = type(ks) ~= 'table' and { ks } or ks
    local l = #ks
    local dst = package.user

    for i = 1, l - 1 do
      local k = ks[i]
      dst[k] = {}
      dst = dst[k]
    end

    dst[ks[l]] = value
  end,

  ---Update package.user table
  ---@param ks (string|integer)[]
  ---@param value any
  ---@return boolean
  set = function(ks, value)
    ks = type(ks) ~= 'table' and { ks } or ks
    local l = #ks
    local dst = package.user

    for i = 1, l - 1 do
      local k = ks[i]
      local v = dst[k]

      if type(v) ~= 'table' then
        return false
      else
        dst = v
      end
    end

    dst[ks[l]] = value
    return true
  end,

  ---Check if a key exists
  ---@param ks (string|integer)[]
  ---@return boolean
  has = function(ks)
    ks = type(ks) ~= 'table' and { ks } or ks
    local l = #ks
    local dst = package.user

    for i = 1, l - 1 do
      local k = ks[i]
      local v = dst[k]

      if type(v) ~= 'table' then
        return false
      else
        dst = v
      end
    end

    return dst[ks[l]] ~= nil
  end,

  ---Get value from package.user
  ---@param ks (string|integer)[]
  ---@return any?
  get = function(ks)
    ks = type(ks) ~= 'table' and { ks } or ks
    local l = #ks
    local dst = package.user

    for i = 1, l - 1 do
      local k = ks[i]
      local v = dst[k]

      if type(v) ~= 'table' then
        return
      else
        dst = v
      end
    end

    return dst[ks[l]]
  end,

  ---Unset key from package.user.table
  ---@param ks (string|integer)[]
  ---@return any?
  unset = function(ks)
    ks = type(ks) ~= 'table' and { ks } or ks
    local l = #ks
    local dst = package.user

    for i = 1, l - 1 do
      local k = ks[i]
      local v = dst[k]

      if type(v) ~= 'table' then
        return
      else
        dst = v
      end
    end

    local v = dst[ks[l]]
    dst[ks[l]] = nil

    return v
  end,

  ---@param name string
  ---@param tbl table|function
  ---@param force? boolean
  ---@param include? boolean
  ---@return boolean
  include = function(name, tbl, force, include)
    include = (name == nil and true) or include
    if force or not package.user.lib[name] then
      return false
    elseif include then
      for key, value in pairs(tbl) do
        package.user.lib[key] = value
      end
    else
      package.user.lib[name] = tbl
    end
    return true
  end,

  ---@param specs table<string,any>
  ---@param force? boolean
  ---@return {[string]: boolean}
  include_from_table = function(specs, force)
    local res = {}
    for key, value in pairs(specs) do
      if force or not package.user.lib[key] then
        package.user.lib[key] = value
        res[key] = true
      else
        res[key] = false
      end
    end
    return res
  end,
}

package.user.loaded = true

---@class class<T>
---@field new fun(self, ...: any): instance<`T`>
---@field initialize fun(self, ...: any)
---@field __type "class"
---@field __name string
---@field __class? class

---@class instance<T>
---@field __type "instance"
---@field __name string
---@field __class class<`T`>

---@class callable
---@field __call fun(self, ...: any): any

---@alias object class | instance
---@alias num number
---@alias str string
---@alias int integer
---@alias func function
---@alias bool boolean
---@alias fileHandle file*
---@alias na nil

package.user.lib.builtin_types = package.user.builtin_types
package.user.lib.classes = package.user.classes
package.user.lib.types = package.user.types
package.user.lib.guards = package.user.guards

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
---@param mt? table
---@return table
function bless(x, mt)
  x = x or {}
  mt = mt or x
  return setmetatable(x, mt)
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

--- Track globals explicitly and wrap up
unpack = unpack or table.unpack
local include = package.user.include_from_table
local gset = function(specs)
  for key, value in pairs(specs) do
    package.user.lib.gset(key, value)
  end
end
local globals = {
  sequence = sequence,
  callable = callable,
  dump = dump,
  pp = pp,
  printf = printf,
  sprintf = sprintf,
  errorf = errorf,
  pack = pack,
  unpack = unpack or table.unpack,
  rtostring = rtostring,
  is_nil = is_nil,
  as_value = as_value,
  bless = bless,
}
include(globals)
gset(globals)

-- Do not touch
package.user.loaded = true

return package.user
