require 'lib.definitions'

local lib = package.user.lib
local is = lib.is
local copy = vim.deepcopy
local make_command = vim.api.nvim_create_user_command
local make_buffer_command = vim.api.nvim_buf_create_user_command
local make_autocmd = vim.api.nvim_create_autocmd
local state = package.user.state.command

---@class command.utils
local command = {
  __index = rawget,
  validator = { is.string, is.callable, is.table }
}
setmetatable(command, command)

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

---@alias command.callback fun(args: string|string[], rest: command.args)

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
---@field safe boolean alias for .pcall
---@field process fun(x: string): any
---@field filter fun(x: string): boolean

---@class command.spec
---@field [1]? string
---@field [2]? command.callback
---@field [3]? command.opts
---@field name? string
---@field callback command.callback
---@field opts? command.opts

---@class command
---@field name string
---@field callback command.callback
---@field opts? command.opts

---@param name string
---@param callback command.callback
---@param opts? table
---@return command
function command.new(name, callback, opts)
  opts = opts or {}
  local nargs = opts.nargs
  local bang = opts.bang
  local desc = opts.desc
  local force = opts.force
  local trim = opts.trim
  local process = opts.process
  local filter = opts.filter
  local event = opts.event
  local pattern = opts.pattern
  local buf = opts.buffer
  local should_pcall = opts.pcall
  local _args = { name, callback, opts }
  local cmd_opts = { bang = bang, desc = desc, force = force, nargs = nargs }
  local run = function(args)
    local process_arg = function(arg)
      if arg == '' then
        return
      end

      if trim then
        arg = trim(arg)
      end

      if filter and not filter(arg) then
        return
      elseif process then
        return process(arg)
      else
        return arg
      end
    end
    local collect_args = function(fargs)
      local res = {}
      for i = 1, #fargs do
        local value = process_arg(fargs[i])
        if value ~= nil then res[#res + 1] = value end
      end
      return res
    end
    local call = function(use_args, rest_args)
      if should_pcall then
        return pcall(callback, use_args, rest_args)
      else
        return callback(use_args, rest_args)
      end
    end

    if nargs == 0 then
      return call(nil, args)
    end

    local use = collect_args(args.fargs)
    if nargs == 1 or nargs == '?' then
      return call(use[1], args)
    else
      return call(use, args)
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

  state[name] = _args
  return _args
end

function command.define(opts, specs)
  opts = opts or {}
  for i = 1, #specs do
    local spec = specs[i]
    local name, callback, given_opts = unpack(spec)
    local cmd_opts = dict.merge(copy(given_opts or {}), opts)
    command.new(name, callback, cmd_opts)
  end
end

---@param name string
---@param callback command.callback
---@param opts? command.opts
---@return command
function command:__call(name, callback, opts)
  return command.new(name, callback, opts)
end

---@param spec command.spec
---@return boolean
function command.isa_config(spec)
  lib.assert.spec(spec, command.validator)
  return true
end

return command
