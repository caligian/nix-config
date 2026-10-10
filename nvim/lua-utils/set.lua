---@class Set

---@class Set.utils
---@overload fun(tbl: table): Set
local set = {}
setmetatable(set, set)

---@param x Set
---@param sort? boolean|fun(a: any, b: any): boolean
---@return any[]
function set.as_list(x, sort)
  local res = {}
  for value, _ in pairs(x) do res[#res + 1] = value end

  if sort then
    if type(sort) == 'function' then
      table.sort(res, sort)
    else
      table.sort(res)
    end
  end

  return res
end

---@param x Set
---@return integer
function set.length(x)
  local len = 0
  for _, _ in pairs(x) do len = len + 1 end
  return len
end

---@param x Set
---return boolean
function set.is_empty(x)
  return set.length(x) == 0
end

---@param x Set
---@return boolean
function set.not_empty(x)
  return not set.is_empty(x)
end

---@param x Set
---@param y Set
---@return boolean
function set.has_same_length(x, y)
  return set.length(x) == set.length(y)
end

---@param x Set
---@param y Set
---@return boolean
function set.equals(x, y)
  if set.length(x) ~= set.length(y) then
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
function set.not_equals(x, y)
  if set.length(x) ~= set.length(y) then
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
function set.is_subset(x, y, strict)
  if not strict then
    if set.length(x) > set.length(y) then
      return false
    end
  else
    if set.length(x) >= set.length(y) then
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
function set.is_superset(x, y, strict)
  return set.is_subset(y, x, strict)
end

---@param x Set
---@param y Set
---@return Set
function set.intersection(x, y)
  local res = set.new {}
  for value, _ in pairs(x) do if y[value] then res[value] = true end end
  for value, _ in pairs(y) do if x[value] then res[value] = true end end
  return res
end

---@param x Set
---@param y Set
---@return Set
function set.union(x, y)
  local res = set.new {}
  for value, _ in pairs(x) do res[value] = true end
  for value, _ in pairs(y) do res[value] = true end
  return res
end

---@param x Set
---@param y Set
---@return Set
function set.difference(x, y)
  local res = set.new {}
  for value, _ in pairs(x) do res[value] = true end
  for value, _ in pairs(y) do res[value] = nil end
  return res
end

---@param x Set
---@param f fun(elem: any): any
---@param safe? boolean
---@return Set
function set.map(x, f, safe)
  local res = set.new {}
  for value, _ in pairs(x) do
    if safe then
      local ok
      value = as_value(value)
      ok, value = pcall(f, value)
      if ok then res[value] = true end
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
function set.filter(x, f, safe)
  if type(f) == 'string' or (type(f) == 'table' and type(f[1]) == 'string') then
    return set.grep(x, f)
  end

  local res = set.new {}
  for value, _ in pairs(x) do
    if safe then
      value = as_value(value)
      local ok, check = pcall(f, value)
      if ok and check then res[value] = true end
    elseif f(value) then
      res[value] = value
    end
  end
  return res
end

---@param x Set
---@param elems any
---@return boolean[]
function set.has(x, elems)
  local res = {}
  for _, check_value in ipairs(elems) do
    local ind = #res + 1
    res[ind] = true
    if not x[check_value] then res[ind] = false end
  end
  return res
end

---@param x Set
---@param patterns string|string[]
---@return any[]
function set.grep(x, patterns)
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
function set.sort(x, fn)
  if fn then
    table.sort(x, function(a, b)
      a = as_value(a)
      b = as_value(b)
      return fn(a, b)
    end)
  else
    table.sort(x)
  end
  return x
end

---@param tbl? any[]
---@return Set
function set.new(tbl)
  local mt = {}
  local new = setmetatable({}, mt)

  if tbl then
    for _, value in pairs(tbl) do
      new[value] = true
    end
  end

  mt.__call = set.as_list
  mt.__add  = set.union
  mt.__sub  = set.difference
  mt.__le   = set.is_subset
  mt.__mod  = set.grep
  mt.__div  = set.filter
  mt.__lt   = function(x, y) return set.is_subset(x, y, true) end
  mt.type   = 'set'

  return new
end

---@param x any
---@return boolean
function set.is_set(x)
  if type(x) == 'table' then
    local mt = getmetatable(x)
    if not mt then
      return false
    else
      return mt.type == 'set'
    end
  end

  return false
end

---@param tbl table
---@return Set
function set:__call(tbl)
  return set.new(tbl)
end

return set
