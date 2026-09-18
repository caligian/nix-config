local copy = vim.deepcopy
local types = require 'lua-utils.type'
local dict = require 'lua-utils.dict'
local is = types.is
local as = types.as
local utils = {}
local M = { __index = rawget }

local function check_pattern(str, patterns)
  patterns = as.list(patterns)
  for i = 1, #patterns do
    local pattern = patterns[i]
    local ok = false

    if is.string(pattern) then
      ok = string.match(str, pattern) ~= nil
    elseif is.fun(pattern) then
      ok = pattern(str)
    end

    if ok then
      return true
    end
  end

  return false
end

---@param keys string | integer | (string|integer)[]
---@return table
function M:__sub(keys)
  local mt = getmetatable(self)
  local res = utils.new({}, mt.include, mt.exclude)

  for key, value in pairs(self) do
    res[key] = value
  end

  for i = 1, #keys do
    local k = keys[i]
    res[k] = nil
  end

  return res
end

function M:__add(other)
  self = copy(self)
  local mt = getmetatable(self)

  for key, value in pairs(other) do
    if check_pattern(key, mt.include, mt.exclude) then
      self[key] = value
    end
  end

  return self
end

function M:__div(test_spec)
  local mt = getmetatable(self)
  local function test(config, spec, res)
    for key, value in pairs(spec) do
      if is.fun(value) then
        if value(config[key]) then
          res[key] = config[key]
        end
      elseif is.pure_table(value) and is.pure_table(config[key]) then
        res[key] = copy(config[key])
        test(config[key], value, res[key])
      elseif value then
        res[key] = config[key]
      end
    end
  end

  local res = utils.new({}, mt.include, mt.exclude)
  test(self, test_spec, res)
  return res
end

function M:__mul(other)
  local mt = getmetatable(self)
  local function merge(config, spec, res)
    for key, value in pairs(spec) do
      if is.pure_table(value) and is.pure_table(config[key]) then
        res[key] = copy(config[key])
        merge(config[key], value, res[key])
      else
        res[key] = value
      end
    end
  end

  local res = utils.new({}, mt.include, mt.exclude)
  merge(self, other, res)
  return res
end

---@param ks string|number|(string|number[])
---@return table
function M:__mod(ks)
  local res = {}
  ks = as.list(ks)

  for _, key in ipairs(ks) do
    key = as.list(key)
    res[key[1]] = dict.get(self, key)
  end

  local mt = getmetatable(self)
  return utils.new(res, mt.include, mt.exclude)
end

function utils.new(x, include, exclude)
  local mt = copy(M)
  include = include and as.list(include)
  exclude = exclude and as.list(exclude)
  mt.include = include
  mt.exclude = exclude
  x = setmetatable(x or {}, mt)

  function mt:__newindex(key, value)
    if exclude and check_pattern(key, exclude) then
      errorf("Key %s matches excluded patterns [%s]", key, exclude)
    elseif include then
      if check_pattern(key, include) then
        rawset(self, key, value)
      else
        errorf("Include pattern [%s] failed for key %s", include, key)
      end
    else
      rawset(self, key, value)
    end
  end

  return x
end

---@param x table
---@return table
function utils.as_table(x)
  x = copy(x)
  setmetatable(x, nil)
  return x
end

return utils
