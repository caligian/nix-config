require 'lib.definitions'

local lib = package.user.lib
local check = lib.assert
local union = lib.union
local is = lib.is
local dict = lib.dict
local fs = lib.fs
local copy = require 'lua-utils.copy'

local terminal = require 'lib.terminal'
local buffer = require 'lib.buffer'
local project = require 'lib.project'
local kbd = require 'lib.keymap'
local timer = require 'lib.timer'
local nvim = require 'lib.nvim'
local shell = require 'lib.shell'
local filetypes = package.user.config.filetype
local state = package.user.state.repl or {}

local repl = {
  validator = {
    cmd = union('string', 'callable'),
    opt_opts = {
      opt_input = {
        opt_map = is.callable,
        opt_file = {
          opt_use = is.boolean,
          opt_format = is.string,
        },
        opt_format = is.string,
        opt_cd = is.string,
      },
      opt_root = {
        opt_check_depth = is.number,
      }
    }
  }
}

---@param bufnr integer
---@param what? string Any of cmd | root | input
function repl.get_config(bufnr, what)
  bufnr = shell.getbufnr(bufnr)
  local ft = buffer.get_filetype(bufnr)
  local ft_obj = filetypes[ft]
  local config

  if not ft_obj or not dict.has(ft_obj, { 'config', 'repl' }) then
    return
  else
    config = ft_obj.config.repl
  end

  if not what then
    return {
      cmd = config.cmd,
      root = config.root,
      input = config.input,
    }
  else
    return config[what]
  end
end

function repl.new(bufnr)
  local ft = buffer.get_filetype(bufnr)
  local config = repl.get_config(bufnr)

  if not config then
    printf("No REPL configuration for filetype %s exists", ft)
    return
  end

  local proj = project.find_by_buffer(bufnr, config.root)
  proj = proj or buffer.get_dirname(bufnr)

  if not fs.is_dir(proj) then
    printf("Nonexistent directory %s", proj)
  elseif dict.has(state, { ft, proj }) then
    local term = dict.get(state, { ft, proj })
    if term:is_running() then
      return term
    end
  end

  local term = terminal(proj, config.cmd)
  dict.force_set(state, { ft, proj }, term)
  return term
end

function repl.get(bufnr)
  bufnr = shell.getbufnr(bufnr)
  local root = repl.get_config(bufnr, 'root')
  local proj = project.find_by_buffer(bufnr, root)
  local ft = buffer.filetype(bufnr)

  if proj and ft then
    return dict.get(state, { ft, proj })
  elseif ft == '' or vim.fn.bufname(bufnr) == '' then
    printf("Cannot run REPL for an unnamed buffer")
  elseif not proj then
    printf("No project directory found for buffer %d [%s]", bufnr, ft)
  end
end

function repl.if_exists(bufnr, fn)
  local term = repl.get(bufnr)
  if term then
    return fn(term)
  end
end

function repl.is_running(bufnr)
  return repl.if_exists(bufnr, function(term)
    return term:is_running()
  end)
end

function repl.if_running(bufnr, fn)
  return repl.if_exists(bufnr, function(term)
    return term:is_running() and fn(term)
  end)
end

function repl.start(bufnr)
  local term = repl.new(bufnr)
  if not term then
    return
  else
    return term:start()
  end
end

---@param bufnr integer
---@param timeout? integer
---@param retries? integer
---@return boolean?
function repl.stop(bufnr, timeout, retries)
  local term = repl.get(bufnr)
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
function repl.hide(bufnr)
  return repl.if_running(bufnr, function(term)
    return term:hide()
  end)
end

---@param bufnr integer
---@param direction? string
---@param resize? string|integer
---@return boolean?
function repl.split(bufnr, direction, resize)
  return repl.if_running(bufnr, function(term)
    return term:split(direction, resize)
  end)
end

---@param bufnr integer
---@param resize? string|integer
---@return boolean?
function repl.split_right(bufnr, resize)
  return repl.if_running(bufnr, function(term)
    return term:split('v', resize)
  end)
end

---@param resize? string|integer
---@return boolean?
function repl.split_below(bufnr, resize)
  return repl.if_running(bufnr, function(term)
    return term:split('s', resize)
  end)
end

---@param text string
---@param delete_after? integer ms to delete the file after
---@return string?
function repl.mktempfile(text, delete_after)
  local file = vim.fn.tempname()
  local fh = io.open(file, 'w')

  if not fh then
    return
  end

  fh:write(text)
  fh:close()

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

---@class repl.send.opts.input.file
---@field format? string %file will be replaced with the name of the tempfile while '%s' will contain the string
---@field use? boolean

---@class repl.send.opts
---@field file? repl.send.opts.input.file
---@field apply? (fun(str: string[]): string|string[])

---@param bufnr integer
---@param s string
---@param opts? repl.send.opts
---@return boolean?
function repl.send(bufnr, s, opts)
  return repl.if_running(bufnr, function(term)
    local conf = copy(repl.get_config(bufnr, 'input') or {})
    opts = opts or {}
    opts = dict.merge(conf, opts)
    local file_opts = opts.file or {}
    local send_format = file_opts.format
    local use_file = file_opts.use
    local apply = opts.apply
    s = apply and apply(s) or s
    local file = use_file and repl.mktempfile(s, 3000)

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

function repl.send_current_line(bufnr, opts)
  bufnr = shell.getbufnr(bufnr)
  local line = buffer.call(bufnr, function()
    return vim.fn.getline(vim.fn.line("."))
  end)
  return repl.send(bufnr, line, opts)
end

function repl.send_buffer(bufnr, opts)
  bufnr = shell.getbufnr(bufnr)
  local lines = buffer.as_string(bufnr)
  return repl.send(bufnr, lines, opts)
end

function repl.send_till_cursor(bufnr, opts)
  bufnr = shell.getbufnr(bufnr)
  local pos = buffer.get_curpos(bufnr)
  local lines = buffer.get_lines(bufnr, 0, pos.lnum, false)
  lines = table.concat(lines, "\n")
  return repl.send(bufnr, lines, opts)
end

function repl.send_region(bufnr, opts)
  bufnr = shell.getbufnr(bufnr)
  local region = buffer.call(bufnr, function()
    return nvim.region(false)
  end)

  if region then
    return repl.send(bufnr, region, opts)
  end
end

function repl.setup_keymaps()
  local map = function(mode, lhs, func, opts)
    kbd.map(mode, lhs, function()
      if is.string(func) then
        repl[func](buffer.current())
      else
        func(buffer.current())
      end
    end, opts)
  end
  local nmap = function(lhs, func, opts)
    map('n', '<leader>' .. lhs, func, opts)
  end
  local vmap = function(lhs, func, opts)
    map('v', '<leader>' .. lhs, func, opts)
  end

  nmap('rr', function()
    local buf = buffer.current()
    repl.new(buf)
    repl.start(buf)
  end, { desc = 'Start workspace REPL' })

  nmap('rk', 'hide', { desc = 'Hide terminal' })
  nmap('rq', 'stop', { desc = 'Stop terminal' })
  nmap('re', 'send_current_line', { desc = 'Send current line' })
  vmap('re', 'send_region', { desc = 'Send region' })
  nmap('rb', 'send_buffer', { desc = 'Send buffer' })
  nmap('r.', 'send_till_cursor', { desc = 'Send lines till cursor' })
  nmap('rs', 'split_below', { desc = 'Split below' })
  nmap('rv', 'split_right', { desc = 'Split right' })
end

---Assert tbl is a repl configuration table
---@param tbl table
function repl.isa_config(tbl)
  check.spec(tbl, repl.validator)
end

function repl.setup()
  repl.setup_keymaps()
end

return repl
