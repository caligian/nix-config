require 'lua-utils.string'
local list = require 'lua-utils.list'

local options = require 'lib.options'
local copy = vim.deepcopy
local make_command = vim.api.nvim_create_user_command
local make_buffer_command = vim.api.nvim_buf_create_user_command
local make_autocmd = vim.api.nvim_create_autocmd
local command = {}

---@class command.valid_completion
command.valid_completion = {
  arglist = true,
  augroup = true,
  breakpoint = true,
  buffer = true,
  color = true,
  command = true,
  compiler = true,
  diff_buffer = true,
  dir = true,
  dir_in_path = true,
  environment = true,
  event = true,
  expression = true,
  file = true,
  file_in_path = true,
  filetype = true,
  ['function'] = true,
  help = true,
  highlight = true,
  history = true,
  keymap = true,
  locale = true,
  lua = true,
  mapclear = true,
  mapping = true,
  menu = true,
  messages = true,
  option = true,
  packadd = true,
  runtime = true,
  scriptnames = true,
  shellcmd = true,
  shellcmdline = true,
  sign = true,
  syntax = true,
  syntime = true,
  tag = true,
  tag_listfiles = true,
  user = true,
  var = true,
}

---@class command.args
---@field name string
---@field args string
---@field fargs string[]
---@field bang boolean
---@field start_line integer
---@field end_line integer
---@field count integer

---@class command.opts
---@field bang boolean
---@field complete (fun(): string[])|string
---@field desc string
---@field force boolean (default: true)
---@field nargs integer|string Any of {integer}|[+*?] (default: 0)
---@field event string|string[]
---@field pattern string|string[]
---@field buffer integer
---@field pcall boolean
---@field process fun(x: string|string[]): any
---@field split string

---@param name string
---@param callback fun(args: string|string[], rest: command.args)
---@param opts? table
function command.new(name, callback, opts)
  opts = options.new(opts)
  local cmd_opts = opts / { bang = true, complete = true, desc = true, force = true, nargs = true, }
  cmd_opts.nargs = cmd_opts.nargs or 0
  local event = opts.event
  local pattern = opts.pattern
  local buf = opts.buffer
  local should_pcall = opts.pcall
  local split = opts.split
  local process = opts.process or function(args) return args end
  local run = function(args)
    local use = args.args
    use = split and string.split(use, split) or use
    if type(use) == 'table' then
      use = list.map(use, process)
    else
      use = process(use)
    end

    if should_pcall then
      pcall(callback, use, args)
    else
      callback(use, args)
    end
  end

  if event or pattern then
    event = event or 'BufReadPost'
    pattern = pattern or '*.*'
    make_autocmd(event, {
      pattern = pattern,
      callback = function(args)
        make_buffer_command(args.buf, name, run, cmd_opts)
      end,
      once = true,
    })
  elseif buf then
    make_buffer_command(buf, name, run, cmd_opts)
  else
    make_command(name, run, cmd_opts)
  end
end

---@class command.spec
---@field [1] string
---@field [2] fun(args: string, fargs: string[], rest: command.args)
---@field [3]? command.opts

---@class command.define
---@overload fun(opts?: command.opts, specs: command.spec[])
command.define = {}
setmetatable(command.define, command.define)

function command.define:__call(opts, specs)
  opts = opts or {}
  for i = 1, #specs do
    local spec = specs[i]
    local name, callback, given_opts = unpack(spec)
    local cmd_opts = copy(given_opts)
    cmd_opts.event = spec.event or cmd_opts.event
    cmd_opts.pattern = spec.pattern or cmd_opts.pattern
    cmd_opts.buffer = spec.buffer or cmd_opts.buffer
    cmd_opts.split = spec.split or cmd_opts.split
    cmd_opts.process = spec.process or cmd_opts.process
    command.new(name, callback, given_opts)
  end
end

---@param buf integer
---@param opts? command.opts
---@param specs command.spec[]
function command.define.buffer(buf, opts, specs)
  opts = copy(opts or {})
  opts.buffer = buf
  command.define(opts, specs)
end

---@param event string|string[]
---@param pattern string|string[]
---@param opts? command.opts
---@param specs command.spec[]
function command.define.autocmd(event, pattern, opts, specs)
  opts = copy(opts or {})
  opts.event = event
  opts.pattern = pattern
  command.define(opts, specs)
end

return command
