require 'lib.definitions'

local lib                  = package.user.lib
local list                 = lib.list
local is                   = lib.is
local union                = is.union
local copy                 = vim.deepcopy
local enable               = vim.api.nvim_create_autocmd
local options              = require 'lib.options'

package.user.state.autocmd = package.user.state.autocmd or {}
local state                = package.user.state.autocmd

---@class autocmd.callback.args
---@field id integer
---@field event string
---@field file string
---@field name string
---@field fullname string
---@field match string
---@field buf integer
---@field buffer integer
---@field data any
---@field dirname string
---@field basename string

---@alias autocmd.event string|string[]
---@alias autocmd.pattern string|string[]
---@alias autocmd.callback string|fun(buf: integer, args: autocmd.callback.args)

---@class autocmd.opts
---@field pattern? autocmd.pattern|integer
---@field group string|integer
---@field buffer? integer
---@field buf? integer
---@field desc? string
---@field callback? autocmd.callback
---@field command?  autocmd.callback
---@field once? boolean
---@field nested? boolean
---@field pcall? boolean

---@class autocmd.spec
---@field [1] autocmd.event
---@field [2] autocmd.callback
---@field [3]? autocmd.opts

---@class autocmd
---@field id? integer
---@field name? string|integer
---@field event autocmd.event
---@field callback? autocmd.callback
---@field command? autocmd.callback
---@field desc? string
---@field pattern? autocmd.pattern|integer
---@field pat? autocmd.pattern|integer
---@field buffer? integer
---@field buf? integer

---@class autocmd.utils
---@overload fun(event: autocmd.event, callback: autocmd.callback, opts?: autocmd.opts|string|integer): autocmd
local autocmd              = {
  validator = {
    union(is.string, is.list),
    union(is.callable, is.string),
    union(is.table, is.string),
  }
}

---Valid options
---@type {[string]: boolean}
autocmd.valid_opts         = {
  pattern = true,
  group = true,
  buffer = true,
  desc = true,
  callback = true,
  command = true,
  once = true,
  nested = true,
}

---@param event? string|string[]
---@param callback string|fun(buf: integer, args: autocmd.callback.args)
---@param opts? autocmd.opts
---@return integer
function autocmd.new(event, callback, opts)
  local args = copy { event, callback, opts }
  opts = type(opts) == 'string' and { desc = opts } or opts
  opts = options.new(opts)
  local should_pcall = opts.pcall

  if is.string(callback) then
    opts.command = callback
  else
    opts.callback = function(_args)
      if should_pcall then
        pcall(callback, _args.buf, _args)
      else
        callback(_args.buf, _args)
      end
    end
  end

  local id = enable(event, opts)
  state[id] = args
  return id
end

---@param opts table
---@param specs autocmd.spec[]
---@return integer[]
function autocmd.define(opts, specs)
  local res = {}
  opts = opts or {}

  for i = 1, #specs do
    local spec = specs[i]
    local event, callback, given = unpack(spec)
    given = given or {}
    given = is.string(given) and { desc = given } or given
    given = copy(given)

    for key, value in pairs(opts) do
      if given[key] == nil then
        given[key] = value
      end
    end

    res[i] = autocmd.new(event, callback, given)
  end

  return res
end

---@param pattern string|string[]
---@param callback like_function
---@param opts? autocmd.opts|string
---@return integer
function autocmd.ft_new(pattern, callback, opts)
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  opts = copy(opts)
  opts.pattern = pattern
  return autocmd.new('Filetype', callback, opts)
end

---@param ft string|string[]
---@param opts table?
---@param specs autocmd.spec[]
---@return integer[]
function autocmd.ft_define(ft, opts, specs)
  opts = opts or {}
  local res = {}

  for i = 1, #specs do
    local spec = specs[i]
    local callback, given = unpack(spec)
    given = given or {}
    given = is.string(given) and { desc = given } or given
    given = copy(given)
    given.pattern = ft

    for key, value in pairs(opts) do
      if given[key] == nil then
        given[key] = value
      end
    end

    res[i] = autocmd.new('Filetype', callback, given)
  end

  return res
end

---@param id integer
---@return boolean
function autocmd.is_valid(id)
  return #(vim.api.nvim_get_autocmds { id = id }) ~= 0
end

---@param ids integer[]|integer
---@return boolean[]
function autocmd.are_valid(ids)
  ids = as.list(ids)
  return list.map(ids, autocmd.is_valid)
end

---@param spec autocmd.spec
---@return boolean
function autocmd.isa_config(spec)
  lib.assert.spec(spec, autocmd.validator)
  return true
end

autocmd.map = autocmd.new
autocmd.ft_map = autocmd.ft_new


return autocmd
