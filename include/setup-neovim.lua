require 'lua-utils.dump'

local globals = require 'lua-utils.globals'
local str = require 'lua-utils.string'
local list = require 'lua-utils.list'
local dict = require 'lua-utils.dict'
local types = require 'lua-utils.type'
local assert = require 'lua-utils.assert'
local inspect = require 'lua-utils.inspect'
local set = require 'lua-utils.set'
local result = require 'lua-utils.result'
local tuple = require 'lua-utils.tuple'
local path = require 'lua-utils.fs'
local metatable = require 'lua-utils.metatable'
local process = require 'lua-utils.process'
local options = {
  tabstop = 4,
  shiftwidth = 4,
  softtabstop = 4,
  expandtab = true,
  autoindent = true,
  autochdir = false,
  background = 'dark',
  cursorline = false,
  wildmenu = true,
  wildmode = 'longest:full,full',
  number = true,
  relativenumber = true,
  termguicolors = true,
  clipboard = 'unnamedplus',
}

local map = vim.keymap.set
local on = vim.api.nvim_create_autocmd

for key, value in pairs(options) do
  vim.o[key] = value
end

map('n', '<leader>lf', ':Format<CR>', { desc = "Format buffer" })

on('LspAttach', {
  callback = function(args)
    pcall(function()
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
      require("lsp-format").on_attach(client, args.buf)
    end)
  end,
})

---@class user
package.user = {}

---@class user.lib
package.user.lib = {}
package.user.lib.pack = tuple.pack
package.user.lib.unlink = path.rmtree
package.user.lib.abspath = path.abspath
package.user.lib.is_plist = types.is_pure_list
package.user.lib.is_pdict = types.is_pure_dict
package.user.lib.is_ptable = types.is_pure_table
package.user.lib.is_mount = path.is_mount
package.user.lib.is_link = path.is_link
package.user.lib.is_file = path.is_file
package.user.lib.is_dir = path.is_dir
package.user.lib.dirname = path.dirname
package.user.lib.basename = path.basename
package.user.lib.list_files = path.list_files
package.user.lib.glob = path.glob
package.user.lib.filetype = path.mode
package.user.lib.validate = types.validate
package.user.lib.class = types.class
package.user.lib.maybe = types.maybe
package.user.lib.optional = types.maybe
package.user.lib.union = types.union
package.user.lib.is = types.is
package.user.lib.isa = types.isa
package.user.lib.as = types.as
package.user.lib.defcallable = types.defcallable
package.user.lib.deftype = types.deftype
package.user.lib.defguard = types.defguard
package.user.lib.defmulti = types.defmulti
package.user.lib.defclass = types.defclass
package.user.lib.foreach = types.foreach
package.user.lib.callable = types.callable
package.user.lib.hasmetatable = types.hasmetatable
package.user.lib.classof = types.classof
package.user.lib.instanceof = types.instanceof
package.user.lib.reduce = types.reduce
package.user.lib.reverse = types.reverse
package.user.lib.typeof = types.typeof
package.user.lib.is_subclass = types.is_subclass
package.user.lib.unique = types.unique
package.user.lib.mt_get = types.mt_get
package.user.lib.mt_set = types.mt_set
package.user.lib.has_mt = types.hasmetatable
package.user.lib.get_mt = getmetatable
package.user.lib.set_mt = setmetatable
package.user.lib.callable = types.callable
package.user.lib.bless = types.bless
package.user.lib.types = types
package.user.lib.list = list
package.user.lib.dict = dict
package.user.lib.copy = copy
package.user.lib.tuple = tuple
package.user.lib.set = set
package.user.lib.NIL = package.NIL
package.user.lib.GUARD = package.GUARD
package.user.lib.unpack = unpack or table.unpack
package.user.lib.is_table = types.is_table
package.user.lib.is_string = types.is_string
package.user.lib.is_userdata = types.is_userdata
package.user.lib.is_function = types.is_function
package.user.lib.is_list = types.is_list
package.user.lib.is_dict = types.is_dict
package.user.lib.is_guard = types.is_guard
package.user.lib.is_boolean = types.is_boolean
package.user.lib.is_class = types.is_class
package.user.lib.is_instance = types.is_instance
package.user.lib.is_builtin_type = types.is_builtin_type
package.user.lib.is_object = types.is_object
package.user.lib.is_union = types.is_union
package.user.lib.is_pure_list = types.is_pure_list
package.user.lib.is_pure_dict = types.is_pure_dict
package.user.lib.is_pure_table = types.is_pure_table
package.user.lib.is_thread = types.is_thread
package.user.lib.fs = path
package.user.lib.path = path
package.user.lib.system = process.system
package.user.lib.systemlist = process.systemlist
package.user.lib.process = process
package.user.lib.inspect = inspect
package.user.lib.result = result
package.user.lib.Ok = result.Ok
package.user.lib.Err = result.Err
package.user.lib.str = str
package.user.lib.metatable = metatable
package.user.lib.NIL = globals.NIL
package.user.lib.GUARD = globals.GUARD
package.user.lib.BACKUP = globals.BACKUP
package.user.lib.BUILTIN_TYPES = globals.BUILTIN_TYPES

---@class user.state
package.user.state = {}

---@type {[number]: autocmd}
package.user.state.autocmd = {}

---@type {[string]: keymap}
package.user.state.keymap = {}

---@class user.state.terminal
---@field id {[number]: terminal}
---@field pid {[number]: terminal}
package.user.state.terminal = { id = {}, pid = {} }

---@type {[string]: filetype}
package.user.state.filetype = {}

---@type {[string]: {[string]: terminal}}
package.user.state.repl = {}

---@type {[string]: string}
package.user.state.workspace = {}

---@type {[number]: table}
package.user.state.buffer = {}

---@type command[]
package.user.state.command = {}

---@type {[string]: augroup}
package.user.state.augroup = {}

---@class user.config
package.user.config = {}

---@class user.config.workspace
package.user.config.workspace = {
  check_depth = 4,
  marker = { '.PROJECT' },
}

---@class user.config.plugins
package.user.config.plugins = {}

---@class user.config.plugins.telescope
package.user.config.plugins.telescope = {
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
    },
    diagnostics = {
      previewer = false,
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
