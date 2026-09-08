local fs = require 'lua-utils.fs'
local copy = require 'lua-utils.copy'
local types = require 'lua-utils.type'
-- local is = types.is
local as = types.as
local dict = require 'lua-utils.dict'
local list = require 'lua-utils.list'
local mydir = os.getenv("MY_DIR") .. "/nvim"
local mylib = mydir .. "/lib"
local myconfig = mydir .. "/config"


---@alias config.key string|number
---@alias config.keys config.keys[]

---@class user
---@field last_setup_result? user.setup.return
local utils = {
  setup_done = false,
  state = {
    autocmd = {},
    keymap = {},
    workspace = {},
    command = {},
    repl = {},
    terminal = {},
    filetype = {},
  },
  last_setup_result = nil,
  config = {
    pkgs = {
      telescope = {
        defaults = {
          layout_config = { height = 0.3 },
          layout_strategy = 'bottom_pane',
          previewer = false,
        },
        pickers = {
          ['*'] = { previewer = false, },
          oldfiles = { previewer = false, },
          find_files = { previewer = false, },
          git_files = { previewer = false, },
          buffers = {
            show_all_buffers = true,
            sort_lastused = true,
            previewer = false,
            mappings = {
              i = { ["<c-d>"] = "delete_buffer", },
              n = { ["dd"] = "delete_buffer", }
            }
          }
        },
        extensions = {
          frecency = {
            previewer = false,
          },
          file_browser = {
            previewer = false,
          },
          project = {
            previewer = false,
          }
        }
      }
    },
    workspace = {
      check_depth = 4,
    }
  }
}

---@type user
package.user = package.user or utils

---@param ks config.key|config.keys
---@param value any
---@return user
function utils.set(ks, value)
  value = types.as_value(value)
  if value == nil then
    error("value cannot be nil. For unsetting values, use utils:unset instead")
  end

  ks = as.list(ks)
  dict.force_set(utils, ks, value)
  return utils
end

function utils.unset(ks)
  ks = as.list(ks)
  dict.unset(utils, ks)
  return utils
end

---@param ks config.key
---@param value any
---@return user
function utils.set_state(ks, value)
  ks = copy.copy(ks)
  ks = as.list(ks)
  table.insert(ks, 1, 'state')
  return utils.set(ks, value)
end

---@param ks config.key
---@return user
function utils.unset_state(ks)
  ks = copy.copy(ks)
  ks = as.list(ks)
  table.insert(ks, 1, 'state')
  return utils.unset(ks)
end

---@param ... string
---@return boolean, any
function utils.require(...)
  local str = table.concat({ ... }, '.')
  local ok, msg = pcall(require, str)
  return ok, msg
end

---@param str string
---@param on_ok fun(result: any): any
---@param on_err? fun(err_msg?: string): any (default: Raise the error message)
---@return any
function utils.map_require(str, on_ok, on_err)
  local ok, msg = utils.require(str)
  on_err = on_err or function(err_msg)
    if err_msg then
      return string.format('require "%s": %s', str, err_msg)
    else
      return string.format('require "%s": ERROR', str)
    end
  end

  if ok then
    if on_ok then return on_ok(msg) end
    return msg
  else
    on_err(msg)
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
function utils.require_pkg(name)
  return pcall(require, 'config.pkgs.' .. name)
end

---@param name string
---@return boolean, any
function utils.load_pkg(name)
  local filename = myconfig .. '/pkgs/' .. name .. '.lua'
  if not fs.is_file(name) then
    return false, string.format('Nonexistent file %s', filename)
  end

  local chunk, msg = loadfile(filename)
  if chunk == nil then
    return false, msg
  end

  return pcall(chunk)
end

---@class user.require_all_pkgs.return
---@field require string
---@field filename string
---@field ok boolean
---@field err boolean
---@field value any
---@field msg? string

---Setup all packages
---@return user.require_all_pkgs.return[]
function utils.require_all_pkgs()
  local dir = myconfig .. '/pkgs'
  local files = fs.glob(string.format("%s/*.lua", dir))

  return list.map(files, function(filename)
    local file = fs.basename(filename)
    file = string.gsub(file, '%.lua$', '')
    local req = string.format('config.pkgs.%s', file)
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

---@class user.load_all_pkgs.return
---@field filename string
---@field ok boolean
---@field err boolean
---@field value any
---@field msg? string

---Load all package configurations
---@return user.load_all_pkgs.return[]
function utils.load_all_pkgs()
  local dir = myconfig .. '/pkgs'
  local files = fs.glob(string.format("%s/*.lua", dir))

  return list.map(files, function(filename)
    local file = fs.basename(filename)
    file = string.gsub(file, '%.lua$', '')
    local req = string.format('config.pkgs.%s', file)
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
---@field pkgs (user.load_all_pkgs.return | user.require_all_pkgs.return)[]
---@field user (user.require_all_configs.return | user.load_all_configs.return)[]

---@class user.setup.overrides
---@field user user.setup.return

---@class user.setup.opts
---@field overrides? user.setup.overrides
---@field load? boolean load files instead of require-ing theme. Use carefully only for debugging purposes
---@field require? boolean (default: true)

---@return user.setup.return
function utils.setup(opts)
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

  local result = { config = {}, pkgs = {}, }
  if load then
    result.config = utils.load_all_configs()
    result.pkgs = utils.load_all_pkgs()
  else
    result.config = utils.require_all_configs()
    result.pkgs = utils.require_all_pkgs()
  end

  require('lib.project').setup()
  state.last_setup_result = result
  if package.user == nil then package.user = utils end

  return state.last_setup_result
end

return utils
