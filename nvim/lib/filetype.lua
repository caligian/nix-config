require 'lib.definitions'

local lib = package.user.lib
local class = lib.class
local is = lib.is
local copy = vim.deepcopy
local fs = lib.fs
local list = lib.list

local repl = require 'lib.repl'
local project = require 'lib.project'
local buffer = require 'lib.buffer'
local keymap = require 'lib.keymap'
local autocmd = require 'lib.autocmd'
local config_dir = vim.env.MY_NVIM_DIR .. '/config/filetype'
local filetypes = package.user.config.filetype

---@class filetype.state
---@field autocmd integer[]

---@class filetype
---@field name string
---@field config table
---@field augroup integer
---@field augroup_name string
---@field state.autocmd integer[]
---@overload fun(name: string): filetype
local filetype = class 'filetype'

function filetype:initialize(name)
  self.name = name
  self.config = {
    keymap = {},
    autocmd = {},
    buffer = { opt = {}, var = {} },
    repl = {},
    workspace = {},
    lsp = {},
  }
  self.state = { autocmd = {}, }
  self.augroup_name = string.format("user.config.filetype.%s", self.name)
  self.augroup = vim.api.nvim_create_augroup(self.augroup_name, { clear = true })
  filetypes[name] = self
end

---@param name string
---@param config table
function filetype:set_lsp_config(name, config)
  self.config.lsp[name] = config
  vim.lsp.config(name, config)
end

---@class filetype.autocmd.opts
---@field once? boolean
---@field desc? string

---@param callback fun(buf: integer, args: autocmd.callback.args)
---@param opts? filetype.autocmd.opts|string
---@return integer
function filetype:on(callback, opts)
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  local spec = { { 'Filetype' }, callback, {
    group = self.augroup_name,
    pattern = self.name,
    once = opts.once,
    desc = opts.desc, ---@diagnostic disable-line
  } }
  local ind = #self.state.autocmd + 1
  local id = autocmd.new(unpack(spec))
  self.state.autocmd[ind] = id
  self.config.autocmd[#self.config.autocmd + 1] = spec

  return id
end

---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param opts? keymap.opts
function filetype:map(mode, lhs, rhs, opts)
  mode = mode or 'n'
  opts = opts or {}
  opts = is.string(opts) and { desc = opts } or opts
  opts = copy(opts)
  opts.event = 'Filetype'
  opts.pattern = self.name
  self.config.keymap[#self.config.keymap + 1] = { mode, lhs, rhs, opts }
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

---@param cmd repl.cmd
---@param opts? repl.opts
function filetype:set_repl_config(cmd, opts)
  repl.isa_config { cmd = cmd, opts = opts }

  opts = opts or {}
  opts = copy(opts)
  opts.root = opts.root or { check_depth = 4 }
  opts.input = opts.input or {}

  local use = function()
    if is.string(cmd) then
      return cmd
    end

    local buf = buffer.current()
    local proj = project.find_by_buffer(buf, opts.root or {})
    local dir = fs.dirname(vim.api.nvim_buf_get_name(buf))
    return cmd(buf, { project = proj, dir = dir, workspace = proj })
  end

  self.config.repl = {
    cmd = use,
    input = opts.input,
    root = opts.root,
  }
end

local utils = {}
utils.filetype = filetype

---@param name string
---@return filetype
function utils.new(name)
  if string.match(name, '%.lua$') then
    name = fs.basename(name)
    name = string.gsub(name, '%.lua$', '')
  end
  return filetype:new(name)
end

---@param name string
---@return filetype?
function utils.load_config(name)
  local p = name
  if not string.match(name, '%.lua') then
    p = fs.join(vim.env.MY_NVIM_DIR, "config", "filetype", name .. '.lua')
  end

  if fs.is_file(p) then
    local ok, _ = loadfile(p)
    if not ok then
      return
    else
      local setup = ok()
      local ft = utils.new(name)
      setup(ft)
      return ft
    end
  end
end

function utils.list_configs()
  local files = fs.list_files(config_dir, true)
  return list.filter(files, function(x) return x:match('%.lua$') end)
end

---@param name string
---@return filetype?
function utils.require_config(name)
  local ok, msg = pcall(require, 'config.filetype.' .. name)
  if not ok then
    return
  else
    local setup = msg
    local ft = utils.new(name)
    setup(ft)
    return ft
  end
end

---@return {[string]: filetype}
function utils.load_all_configs()
  local res = {}
  local files = utils.list_configs()

  for _, file in ipairs(files) do
    local ft = string.gsub(fs.basename(file), '%.lua$', '')
    local out = utils.load_config(file)

    if out then
      res[ft] = out
    end
  end

  return res
end

---@return {[string]: filetype}
function utils.require_all_configs()
  local res = {}
  local files = utils.list_configs()

  for _, file in ipairs(files) do
    local ft = string.gsub(fs.basename(file), '%.lua$', '')
    local out = utils.require_config(ft)

    if out then
      res[ft] = out
    end
  end

  return res
end

utils.setup = utils.require_all_configs

return utils
