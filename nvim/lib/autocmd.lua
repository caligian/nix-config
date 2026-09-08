local types = require 'lua-utils.type'
local is = types.is
local copy = vim.deepcopy
local state = user_config.state.autocmd
local enable = vim.api.nvim_create_autocmd
local options = require 'lib.options'

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
---@alias autocmd.callback string|fun(args: autocmd.callback.args)

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
local autocmd = {}

---Valid options
---@type {[string]: boolean}
autocmd.valid_opts = {
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
  opts = type(opts) == 'string' and { desc = opts } or opts
  opts = options.new(opts)
  local should_pcall = opts.pcall

  if is.string(callback) then
    opts.command = callback
  else
    opts.callback = function(args)
      if should_pcall then
        pcall(callback, args.buf, args)
      else
        callback(args.buf, args)
      end
    end
  end

  local id = enable(event, opts)
  state[id] = { event, opts }
  return id
end

function autocmd.define(opts, specs)
  opts = opts or {}
  for i = 1, #specs do
    local spec = specs[i]
    local event, callback, given = unpack(spec)
    given = given or {}
    given = copy(given)

    for key, value in pairs(opts) do
      if given[key] == nil then
        given[key] = value
      end
    end

    autocmd.new(event, callback, given)
  end
end

return autocmd
