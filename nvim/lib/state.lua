require 'lib.definitions'

local lib = package.user.lib
local is = lib.is
local fs = lib.fs
local dict = lib.dict
local list = lib.list
local autocmd = vim.api.nvim_create_autocmd
local kbd = vim.keymap.set
local mydir = os.getenv("MY_DIR") .. "/nvim"
local mylib = mydir .. "/lib"
local myconfig = mydir .. "/config"

---@alias config.key string|number
---@alias config.keys config.keys[]

local utils = package.user

function utils.clear_gutter_bg()
  local groups = {
    "LineNr",
    "LineNrAbove",
    "LineNrBelow",
    "CursorLineNr",
    "SignColumn",
    "FoldColumn",
    "EndOfBuffer",
  }
  for _, name in ipairs(groups) do
    vim.o.background = 'dark'
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    hl.bg = nil
    hl.ctermbg = nil
    vim.api.nvim_set_hl(0, name, hl)
  end
end

---Basically loadfile("~/.user/config/{name}.lua")
---@param name string
---@return boolean, any
function utils.load_config(name)
  local filename = myconfig .. '/' .. name .. '.lua'
  if not fs.is_file(name) then
    return false, string.format("Nonexistent filename %s", name)
  end

  local chunk, msg = loadfile(filename)
  if chunk ~= nil then
    return true, chunk()
  end

  return false, msg
end

---Basically loadfile("~/.user/config/{name}.lua")
---@param name string
---@return boolean, any
function utils.load_lib(name)
  local filename = mylib .. '/' .. name .. '.lua'
  if not fs.is_file(name) then
    return false, string.format("Nonexistent filename %s", name)
  end

  local chunk, msg = loadfile(filename)
  if chunk ~= nil then
    return true, chunk()
  end

  return false, msg
end

---Load everything in ~/.user/nvim/config/*.lua
---@param name string
---@return boolean, any
function utils.require_config(name)
  if not string.match(name, '^config%.') then name = 'config.' .. name end
  return pcall(require, name)
end

function utils.file2require(filename, ...)
  filename = fs.basename(filename)
  filename = string.gsub(filename, '%.lua$', '')
  return table.concat({ filename, ... }, ".")
end

---@class user.require_all_configs.return
---@field name string
---@field filename string
---@field require string
---@field ok boolean
---@field err boolean
---@field msg? string
---@field value? any

---@return user.require_all_configs.return[]
function utils.require_all_configs()
  return list.map(utils.list_configs(), function(filename)
    local name = utils.file2require(filename)
    local req = 'config.' .. name
    local ok, msg = utils.require_config(name)
    local res = { name = name, filename = filename, require = req, ok = ok, err = not ok }

    if ok then
      res.value = msg
    else
      res.msg = msg
    end

    return res
  end)
end

---@class user.load_all_configs.return
---@field filename string
---@field ok boolean
---@field err boolean
---@field msg? string
---@field value? any

---@return user.load_all_configs.return[]
function utils.load_all_configs()
  return list.map(utils.list_configs(), function(filename)
    local name = string.gsub(fs.basename(filename), '%s.lua', '')
    local ok, msg = utils.load_config(name)
    local res = { filename = filename, ok = ok, err = not ok }

    if ok then
      res.value = msg
    else
      res.msg = msg
    end

    return res
  end)
end

---Load everything in ~/.user/nvim/config/*.lua
---@param name string
---@return boolean, any
function utils.require_lib(name)
  return pcall(require, mylib .. '/' .. name .. '.lua')
end

---@return string[]
function utils.list_configs()
  return fs.glob(myconfig .. "/*.lua")
end

---@return string[]
function utils.list_libs()
  return fs.glob(mylib .. '/*.lua')
end

---@param name string
---@return boolean, any
function utils.require_plugin(name)
  return pcall(require, 'config.plugins.' .. name)
end

---@param name string
---@return boolean, any
function utils.load_plugin(name)
  local filename = myconfig .. '/plugins/' .. name .. '.lua'
  if not fs.is_file(name) then
    return false, string.format('Nonexistent file %s', filename)
  end

  local chunk, msg = loadfile(filename)
  if chunk == nil then
    return false, msg
  end

  return pcall(chunk)
end

---@class user.require_all_plugins.return
---@field require string
---@field filename string
---@field ok boolean
---@field err boolean
---@field value any
---@field msg? string

---Setup all packages
---@return user.require_all_plugins.return[]
function utils.require_all_plugins()
  local dir = myconfig .. '/plugins'
  local files = fs.glob(string.format("%s/*.lua", dir))

  return list.map(files, function(filename)
    local file = fs.basename(filename)
    file = string.gsub(file, '%.lua$', '')
    local req = string.format('config.plugins.%s', file)
    local ok, msg = pcall(require, req)
    local result = {
      ok = ok,
      err = not ok,
      filename = filename,
      require = req,
    }

    if not ok then
      result.msg = msg
    else
      result.value = msg
    end

    return result
  end)
end

---@class user.load_all_plugins.return
---@field filename string
---@field ok boolean
---@field err boolean
---@field value any
---@field msg? string

---Load all package configurations
---@return user.load_all_plugins.return[]
function utils.load_all_plugins()
  local dir = myconfig .. '/plugins'
  local files = fs.glob(string.format("%s/*.lua", dir))

  return list.map(files, function(filename)
    local file = fs.basename(filename)
    file = string.gsub(file, '%.lua$', '')
    local req = string.format('config.plugins.%s', file)
    local ok, msg = pcall(require, req)
    local result = {
      ok = ok,
      err = not ok,
      filename = filename,
      require = req,
    }

    if not ok then
      result.msg = msg
    else
      result.value = msg
    end

    return result
  end)
end

---@class user.setup.return
---@field plugins (user.load_all_plugins.return | user.require_all_plugins.return)[]
---@field user (user.require_all_configs.return | user.load_all_configs.return)[]

---@class user.setup.overrides
---@field user user.setup.return

---@class user.setup.opts
---@field overrides? user.setup.overrides
---@field load? boolean load files instead of require-ing theme. Use carefully only for debugging purposes
---@field require? boolean (default: true)

---@return user.setup.return
function utils.setup(opts)
  vim.g.netrw_banner = 0
  vim.o.smartcase = true
  vim.o.ignorecase = true

  opts = opts or {}
  local force = opts.force
  local load = opts.load
  local overrides = opts.overrides
  local state = package.user or utils

  if state and state.setup_done and not force then
    return state.last_setup_result
  end

  if overrides then
    dict.force_merge(package.user, overrides)
  end

  local result = { config = {}, plugins = {}, }
  if load then
    result.config = utils.load_all_configs()
    result.plugins = utils.load_all_plugins()
  else
    result.config = utils.require_all_configs()
    result.plugins = utils.require_all_plugins()
  end

  require('lib.project').setup()
  require('lib.filetype').setup()
  require('lib.shell').setup()
  require('lib.repl').setup()

  require('themery').setup {
    themes = list.filter(vim.fn.getcompletion("", 'color'), is.string)
  }

  autocmd("ColorScheme", {
    desc = 'Clear gutter color',
    callback = utils.clear_gutter_bg,
    pattern = '*',
  })

  kbd('n', '<leader>hc', ':Themery<CR>', {
    desc = 'Check out themes'
  })

  utils.clear_gutter_bg()
  state.last_setup_result = result

  return state.last_setup_result
end

utils.setup()

return utils
