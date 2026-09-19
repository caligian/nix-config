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

---@alias filetype.repl.cmd string|(fun(buf: integer, args: filetype.repl.cmd.args): string)

---@class filetype.Project
---@field check_depth? integer

---@class filetype.repl.cmd.args
---@field project? string
---@field dir? string

---@class filetype.repl.opts
---@field map fun(str: string[]): string[]
---@field file? boolean
---@field format? string

---@class filetype.repl
---@field cmd string|fun(buf: integer, wd: string): string
---@field input filetype.repl.opts

---@class filetype.Keymap
---@field [1]? string|string[]
---@field [2] string
---@field [3] string|function
---@field [4]? keymap.opts

---@class filetype.Autocmd
---@field [1]? string|string[]
---@field [2] string|function
---@field [3]? autocmd.opts

---@class filetype.Buffer
---@field opt table<string,any>
---@field var table<string,any>

---@class filetype.Config
---@field keymap filetype.Keymap[]
---@field autocmd filetype.Keymap[]
---@field buffer filetype.Buffer

---@class filetype
---@field name string
---@field config table
---@field state table
---@overload fun(name: string): filetype
local filetype = class 'filetype'

function filetype:initialize(name)
  assert_type(name, 'string', 'name')
  self.name = name
  self.config = { keymap = {}, autocmd = {}, buffer = { opt = {}, var = {} } }
  self.state = {}
end

---@class filetype.Autocmd.opts
---@field once? boolean
---@field desc? string

---@param callback fun(buf: integer, args: autocmd.callback.args)
---@param opts? filetype.Autocmd.opts|string
function filetype:on(callback, opts)
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  autocmd.new({ 'filetype' }, callback, {
    pattern = self.name,
    once = opts.once,
    desc = opts.desc
  })
end

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? keymap.opts
function filetype:map(mode, lhs, rhs, opts)
  mode = mode or 'n'
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  opts = copy.copy(opts)
  opts.event = 'filetype'
  opts.pattern = self.name
  keymap.map(mode, lhs, rhs, opts)
end

---@param config {[string]: any}
function filetype:set_opts(config)
  self:on(function(buf, _)
    for key, value in pairs(config) do
      vim.api.nvim_set_option_value(key, value, { buf = buf })
    end
  end)
end

---@param config {[string]: any}
function filetype:set_vars(config)
  self:on(function(buf, _)
    for key, value in pairs(config) do
      vim.api.nvim_buf_set_var(buf, key, value)
    end
  end)
end

---@param cmd filetype.repl.cmd
---@param opts? filetype.repl.opts
---@param proj_opts?
function filetype:set_repl(cmd, opts, proj_opts)
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

-- local lua = filetype('lua')
-- lua:set_repl('luajit', {}, { check_depth = 'a' })
-- pp(lua)

return filetype
