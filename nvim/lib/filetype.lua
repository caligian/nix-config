local project = require 'lib.project'
local Options = require 'lua-utils.Options'
local dict = require 'lua-utils.dict'
local T = require 'lua-utils.type'
local union = T.union
local class = T.class
local is = T.is
local as = T.as
local buffer = require 'lib.buffer'
local keymap = require 'lib.keymap'
local autocmd = require 'lib.autocmd'
local repl_spec = {
  cmd = function(value)
    if not is.string(value) and not is.callable(value) then
      return false, sprintf('repl.cmd: Expected string|callable, got %s', value)
    else
      return true
    end
  end,
  opt_input = {
    opt_map = is.callable,
    opt_file = is.boolean,
    opt_format = is.string,
  },
  opt_project = {
    opt_check_depth = is.number,
  }
}
local keymap_spec = {
  [1] = function(value)
    if not is.list(value) or not is.string(value) then
      return false, sprintf("Expected string|string[], got [%s] %s", type(value), value)
    end
  end,
  [2] = is.string,
  [3] = function(value)
    if not is.callable(value) or not is.string(value) then
      return false, sprintf("Expected string|callable, got [%s] %s", type(value), value)
    end
  end,
  [4] = function(value)
    if not is.string(value) and not is.table(value) then
      return false, sprintf("Expected string|table, got [%s] %s", type(value), value)
    end
  end
}
local autocmd_spec = {
  [1] = function(value)
    if not is.callable(value) or not is.string(value) then
      return false, sprintf("Expected string|callable, got [%s] %s", type(value), value)
    end
  end,
  [2] = function(value)
    if not is.string(value) and not is.table(value) then
      return false, sprintf("Expected string|table, got [%s] %s", type(value), value)
    end
  end
}
local buf_spec = {
  opt_opt = is.table,
  opt_var = is.table,
}

local function assert_type(x, pred, prefix)
  is[pred](x, { assert = true, dump = true, prefix = prefix })
end

---@alias Filetype.Repl.cmd string|(fun(buf: integer, args: Filetype.Repl.cmd.args): string)

---@class Filetype.Project
---@field check_depth? integer

---@class Filetype.Repl.cmd.args
---@field project? string
---@field dir? string

---@class Filetype.Repl.opts
---@field map fun(str: string[]): string[]
---@field file? boolean
---@field format? string

---@class Filetype.Repl
---@field cmd string|fun(buf: integer, wd: string): string
---@field input Filetype.Repl.opts

---@class Filetype.Keymap
---@field [1]? string|string[]
---@field [2] string
---@field [3] string|function
---@field [4]? keymap.opts

---@class Filetype.Autocmd
---@field [1]? string|string[]
---@field [2] string|function
---@field [3]? autocmd.opts

---@class Filetype.Buffer
---@field opt table<string,any>
---@field var table<string,any>

---@class Filetype.Config
---@field keymap Filetype.Keymap[]
---@field autocmd Filetype.Keymap[]
---@field buffer Filetype.Buffer

---@class Filetype
---@field name string
---@field config table
---@field state table
---@overload fun(name: string): Filetype
local Filetype = class 'Filetype'

function Filetype:initialize(name)
  assert_type(name, 'string', 'name')
  self.name = name
  self.config = { keymap = {}, autocmd = {}, buffer = { opt = {}, var = {} } }
  self.state = {}
end

---@class Filetype.Autocmd.opts
---@field once? boolean
---@field desc? string

---@param callback fun(buf: integer, args: autocmd.callback.args)
---@param opts? Filetype.Autocmd.opts|string
function Filetype:on(callback, opts)
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  autocmd.new({ 'Filetype' }, callback, {
    pattern = self.name,
    once = opts.once,
    desc = opts.desc
  })
end

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? keymap.opts
function Filetype:map(mode, lhs, rhs, opts)
  mode = mode or 'n'
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  opts = copy.copy(opts)
  opts.event = 'Filetype'
  opts.pattern = self.name
  keymap.map(mode, lhs, rhs, opts)
end

---@param config {[string]: any}
function Filetype:set_opts(config)
  self:on(function(buf, _)
    for key, value in pairs(config) do
      vim.api.nvim_set_option_value(key, value, { buf = buf })
    end
  end)
end

---@param config {[string]: any}
function Filetype:set_vars(config)
  self:on(function(buf, _)
    for key, value in pairs(config) do
      vim.api.nvim_buf_set_var(buf, key, value)
    end
  end)
end

---@param cmd Filetype.Repl.cmd
---@param opts? Filetype.Repl.opts
---@param proj_opts?
function Filetype:set_repl(cmd, opts, proj_opts)
  local use = function()
    if is.string(cmd) then
      return cmd
    end

    local buf = buffer.current()
    return cmd(buf, {
      project = project.find_by_buffer(buf, proj_opts),
      dir = fs.dirname(vim.api.nvim_buf_get_name(buf))
    })
  end

  opts = opts or {}
  local check = Options { cmd = use, input = opts, project = proj_opts }
  check:assert(repl_spec)
  self.config.repl = { cmd = use, input = opts, project = proj_opts }
end

-- local lua = Filetype('lua')
-- lua:set_repl('luajit', {}, { check_depth = 'a' })
-- pp(lua)

return Filetype
