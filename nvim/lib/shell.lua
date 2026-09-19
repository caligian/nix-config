local path = require 'lua-utils.fs'
local T = require 'lua-utils.type'
local is = T.is
local class = T.class
local terminal = require 'lib.terminal'
local buffer = require 'lib.buffer'
local project = require 'lib.project'
local kbd = require 'lib.keymap'
local command = require 'lib.command'
local timer = require 'lib.timer'
local nvim = require 'lib.nvim'
local shell = {}

local function normalize_buf(buf)
  if buf == nil then
    return vim.fn.bufnr()
  elseif buf == 0 then
    return vim.fn.bufnr()
  else
    return buf
  end
end

package.user.state.shell = package.user.state.shell or {}
package.user.state.tempfiles = package.user.state.tempfiles or {}

---@type {[integer|string]: terminal|string}
local state = package.user.state.shell

---@alias shell.cwd string|(fun(buf: integer): string)
---@alias shell.cmd string|(fun(buf: integer, cwd: string): string)

---@class shell.new.opts.root
---@field check_depth? integer

---@class shell.new.opts
---@field cwd? shell.cwd
---@field cmd? shell.cmd
---@field root? shell.new.opts.root

---@param bufnr integer
---@param opts? shell.new.opts
---@return terminal
function shell.new(bufnr, opts)
  bufnr = bufnr or buffer.current()
  bufnr = bufnr == 0 and buffer.current() or bufnr
  opts = opts or {}
  local root = opts.root or package.user.config.workspace ---@diagnostic disable-line
  local cmd, cwd

  if opts.cwd then
    if is.string(opts.cwd) then
      cwd = opts.cwd
    elseif is.callable(opts.cwd) then
      cwd = opts.cwd(bufnr)
    else
      cwd = os.getenv "HOME"
    end
  else
    cwd = project.find_by_buffer(bufnr, {
      default = buffer.get_dirname,
      check_depth = root.check_depth,
    })
  end

  if state[cwd] and state[cwd]:is_running() then
    return state[cwd]
  end

  if opts.cmd then
    if is.string(opts.cmd) then
      cmd = opts.cmd
    elseif is.callable(opts.cmd) then
      cmd = opts.cmd(bufnr, cwd)
    else
      cmd = ''
    end
  end

  local term = terminal(cwd, cmd)
  state[cwd] = term
  state[bufnr] = cwd ---@diagnostic disable-line

  return term
end

---@param bufnr? integer
---@return terminal?
function shell.get(bufnr)
  bufnr = normalize_buf(bufnr)
  ---@diagnostic disable-next-line
  return state[bufnr] and state[state[bufnr]]
end

---@generic T, E
---@param bufnr integer
---@param ok fun(term: terminal): `T`
---@param err? fun(term: terminal): `E`
---@return (`T`|`E`)?
---@overload fun(term: terminal, ok: fun(term: terminal): `T`, err: nil): `T`?
---@overload fun(term: terminal, ok: nil, err: fun(term: terminal): `E`): `E`?
function shell.if_running(bufnr, ok, err)
  local term = shell.get(bufnr)
  if term == nil then
    return
  elseif term:is_running() then
    return ok(term)
  elseif err then
    return err(term)
  else
    return
  end
end

---@param bufnr integer
---@return boolean?
function shell.start(bufnr)
  local buf = normalize_buf(bufnr)
  local term = shell.get(buf)

  if term then
    return term:start()
  else
    term = shell.new(buf, { cmd = '' })
    if term then
      return term:start()
    else
      return false
    end
  end
end

---@param bufnr integer
---@param timeout integer
---@param retries integer
---@return boolean?
function shell.stop(bufnr, timeout, retries)
  local term = shell.get(bufnr)
  if not term then
    return
  elseif not term:is_running() then
    return false
  end

  term:stop(timeout, retries)
  return true
end

---@param bufnr integer
---@return boolean?
function shell.hide(bufnr)
  return shell.if_running(bufnr, function(term)
    return term:hide()
  end)
end

---@param bufnr integer
---@param direction? string
---@param resize? string|integer
---@return boolean?
function shell.split(bufnr, direction, resize)
  return shell.if_running(bufnr, function(term)
    return term:split(direction, resize)
  end)
end

---@param bufnr integer
---@param resize? string|integer
---@return boolean?
function shell.split_right(bufnr, resize)
  return shell.if_running(bufnr, function(term)
    return term:split('v', resize)
  end)
end

---@param resize? string|integer
---@return boolean?
function shell.split_below(bufnr, resize)
  return shell.if_running(bufnr, function(term)
    return term:split('s', resize)
  end)
end

---@param bufnr integer
---@param dir string
---@return boolean?
function shell.cd(bufnr, dir)
  return shell.if_running(bufnr, function(term)
    return term:cd(dir)
  end)
end

---@param bufnr integer
---@return boolean?
function shell.cd_workspace(bufnr)
  bufnr = normalize_buf(bufnr)
  return shell.if_running(bufnr, function(term)
    return term:cd_buffer_workspace(bufnr)
  end)
end

---@param bufnr integer
---@return boolean?
function shell.cd_dir(bufnr)
  bufnr = normalize_buf(bufnr)
  return shell.if_running(bufnr, function(term)
    return term:cd_buffer_dir(bufnr)
  end)
end

---@param text string
---@param delete_after? integer ms to delete the file after
---@return string?
function shell.mktempfile(text, delete_after)
  local file = vim.fn.tempname()
  local fh = io.open(file, 'w')

  if not fh then
    return
  end

  fh:write(text)

  if delete_after then
    timer('delete-' .. file, delete_after, 0, function()
      if fs.is_file(file) then
        printf("Deleting file %s", file)
        fs.rm(file)
      end
    end)
  end

  return file
end

---@class shell.send.opts.input.file
---@field format? string %file will be replaced with the name of the tempfile while '%s' will contain the string
---@field use? boolean

---@class shell.send.opts
---@field file? shell.send.opts.input.file
---@field apply? (fun(str: string[]): string|string[])

---@param bufnr integer
---@param s string
---@param opts? shell.send.opts
---@return boolean?
function shell.send(bufnr, s, opts)
  return shell.if_running(bufnr, function(term)
    opts = opts or {}
    local file_opts = opts.file or {}
    local send_format = file_opts.format
    local use_file = file_opts.use
    local apply = opts.apply
    s = apply and apply(s) or s
    local file = use_file and shell.mktempfile(s, 3000)

    if use_file and not send_format then
      printf("opts.file.use and opts.file.format must be used together")
    end

    if use_file then
      s = string.gsub(send_format, '%%file', file)
    elseif send_format then
      s = string.format(send_format, s)
    end

    return term:send(s)
  end)
end

function shell.send_current_line(bufnr, opts)
  bufnr = normalize_buf(bufnr)
  local line = buffer.call(bufnr, function()
    return vim.fn.getline(vim.fn.line("."))
  end)
  return shell.send(bufnr, line, opts)
end

function shell.send_buffer(bufnr, opts)
  bufnr = normalize_buf(bufnr)
  local lines = buffer.as_string(bufnr)
  return shell.send(bufnr, lines, opts)
end

function shell.send_till_cursor(bufnr, opts)
  bufnr = normalize_buf(bufnr)
  local pos = buffer.get_curpos(bufnr)
  local lines = buffer.get_lines(bufnr, 0, pos.lnum, false)
  lines = table.concat(lines, "\n")
  return shell.send(bufnr, lines, opts)
end

function shell.send_region(bufnr, opts)
  bufnr = normalize_buf(bufnr)
  local region = buffer.call(bufnr, function()
    return nvim.region(false)
  end)

  if region then
    return shell.send(bufnr, region, opts)
  end
end

function shell.setup_keymaps()
  local fn = setmetatable({}, {
    __index = function(_, fn)
      return function()
        return shell[fn](buffer.current())
      end
    end
  })
  local map = function(mode, lhs, func, opts)
    func = is.string(func) and fn[func] or func
    kbd.map(mode, lhs, func, opts)
  end
  local nmap = function(lhs, func, opts)
    map('n', '<leader>' .. lhs, func, opts)
  end
  local vmap = function(lhs, func, opts)
    map('v', '<leader>' .. lhs, func, opts)
  end

  nmap('<enter><enter>', 'start', { desc = 'Start workspace terminal' })
  nmap('<enter>k', 'hide', { desc = 'Hide terminal' })
  nmap('<enter>q', 'stop', { desc = 'Stop terminal' })
  nmap('<enter>e', 'send_current_line', { desc = 'Send current line' })
  vmap('<enter>e', 'send_region', { desc = 'Send region' })
  nmap('<enter>b', 'send_buffer', { desc = 'Send buffer' })
  nmap('<enter>.', 'send_till_cursor', { desc = 'Send lines till cursor' })
  nmap('<enter>s', 'split_below', { desc = 'Split on right' })
  nmap('<enter>v', 'split_right', { desc = 'Split below' })
  nmap('<enter>d', 'cd_workspace', { desc = 'cd workspace' })
  nmap('<enter>D', 'cd_dir', { desc = 'cd workspace' })
end

function shell.setup()
  shell.setup_keymaps()
end

shell.getbufnr = normalize_buf

return shell
