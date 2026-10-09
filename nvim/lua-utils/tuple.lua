require 'lua-utils.type'

---These functions are potentially performance intensive. Use with care
---@overload fun(...): any[]
local tuple = {}
tuple.__index = tuple
setmetatable(tuple, tuple)
tuple.unpack = table.unpack or unpack

---Pack varargs into a list filling all the nils with false
---@param ... any
---@return any[]
function tuple.pack(...)
  local args = { ... }
  for i = 1, select("#", ...) do
    if args[i] == nil then
      args[i] = package.user.lib.NIL
    end
  end
  return args
end

function tuple:__call(...)
  return tuple.pack(...)
end

---Get size of varargs
---@param ... any
---@return number
function tuple.length(...)
  return select("#", ...)
end

---Similar to lisp's cdr for variadic arguments
---@return any[]
function tuple.cdr(...)
  return tuple.pack(select(2, ...))
end

---@param n number index
---@param ... any
---@return any
function tuple.nth(n, ...)
  local args = tuple.pack(...)
  local len = #args
  n = (n < 0) and (len + n) or n

  return args[n]
end

---Get the first value from variadic arguments
---@return any
function tuple.first(...)
  return tuple.nth(1, ...)
end

tuple.car = tuple.first

---Get the last value from variadic arguments
---@return any
function tuple.last(...)
  local args = tuple.pack(...)
  local len = #args
  return args[len]
end

---Import tuple module to global table
function tuple:import()
  _G.tuple = tuple
end

unpack = unpack or table.unpack
return tuple
