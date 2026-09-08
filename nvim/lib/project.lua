require 'lua-utils.string'

local bufnr = vim.fn.bufnr
local fs = require 'lua-utils.fs'
-- local types = require 'lua-utils.type'
local autocmd = require 'lib.autocmd'
local command = require 'lib.command'
local bufname = vim.api.nvim_buf_get_name
local state = package.user.state.workspace
local project = {}

local function get_check_depth()
  return package.user.config.workspace.check_depth
end

local function get_default()
  return package.user.config.workspace.default or function(buf)
    local path = bufname(buf)
    local dir = fs.dirname(path)

    if dir ~= '..' and dir ~= '.' then
      return
    else
      return dir
    end
  end
end

---@param path string
---@param ... integer buffers
---@return table
function project.track(path, ...)
  state[path] = state[path] or {}
  for _, buf in ipairs({ ... }) do state[path][buf] = path end
  return state[path]
end

---@class project.find.opts
---@field cd? boolean
---@field default? fun(path: string): string
---@field check_depth? integer (default: 4)

---@param path  string
---@param opts? boolean
---@return string?
function project.find(path, opts)
  opts = opts or {}
  local limit = opts.check_depth or get_check_depth()
  local default = opts.default or get_default()
  local cd = opts.cd
  local function find(dir, depth)
    if not dir then
      return
    elseif dir == '/' or limit == depth then
      return
    elseif project.is_dir(dir) then
      return dir
    else
      return find(fs.dirname(dir), depth + 1)
    end
  end

  local dir = find(path, 0)
  if dir == nil then
    if default then
      dir = default()
    else
      return
    end
  end

  if cd then
    vim.fn.chdir(dir)
  end

  return dir
end

---@param buf? integer
---@param opts? project.find.opts
---@return string?
function project.find_by_buffer(buf, opts)
  return project.find(bufname(buf or vim.fn.bufnr()), opts)
end

---@param dir string
---@param buf integer
---@return boolean
function project.has_buffer(dir, buf)
  return state[dir] and state[dir][buf] ~= nil
end

local function matches(ws, patterns)
  for _, pattern in ipairs(patterns) do
    if string.match(ws, pattern) then
      return true
    end
  end
  return false
end

---@param ... string pattern to match against project directories to get buffers
---@return {[1]: integer, [2]: string}[]
function project.list_buffers(...)
  local pats = { ... }
  if #pats == 0 then
    pats[1] = '.+'
  end

  local workspaces = dict.keys(state)
  workspaces = list.filter(workspaces, function(ws)
    return matches(ws, pats)
  end)
  local buffers = {}

  for i = 1, #workspaces do
    local ws = workspaces[i]
    local bufs = state[ws]
    for _bufnr, _ in pairs(bufs) do buffers[_bufnr] = ws end
  end

  local result = {}
  for _bufnr, ws in pairs(buffers) do
    result[#result + 1] = { _bufnr, ws }
  end

  return result
end

---@param path string
---@return boolean
function project.is_dir(path)
  return fs.is_dir(path) and fs.is_file(fs.join(path, '.PROJECT'))
end

function project.list(...)
  local res = {}
  local patterns = { ... }

  list.each(dict.keys(state), function(dir)
    if matches(dir, patterns) then
      res[#res + 1] = dir
    end
  end)

  return res
end

---@class project.refresh.opts
---@field check_depth? integer
---@field default? fun(buf: integer): string?

---@param opts? project.refresh.opts
function project.refresh(opts)
  local buffers = {}
  local rm = {}
  opts = opts or {}
  local check_depth = opts.check_depth or get_check_depth()
  local default = opts.default or get_default()

  for proj, bufs in pairs(state) do
    local invalid = not project.is_dir(proj)
    for buf, _ in pairs(bufs) do
      if bufnr(buf) ~= -1 then
        buffers[buf] = { ok = invalid, dir = proj }
      else
        bufs[buf] = nil
      end
    end

    if invalid then
      rm[#rm + 1] = proj
    end
  end

  for buf, status in pairs(buffers) do
    if not status.ok then
      local proj = project.find_by_buffer(buf, {
        check_depth = check_depth,
        default = default
      })
      if proj then
        state[proj] = state[proj] or {}
        state[proj][buf] = proj
      end
    end
  end

  for i = 1, #rm do
    state[rm[i]] = nil
  end
end

---@param dir string
function project.cd(dir)
  vim.cmd.cd(dir)
end

local function trim(s)
  s = string.gsub(s, "^~", os.getenv "HOME")
  s = string.trim(s)
  s = string.gsub(s, "/+$", "")
  return s
end

function project.setup_commands()
  command.new('ProjectInit', function(args, _)
    local dir = trim(args)
    if not fs.is_dir(dir) then
      printf('Invalid directory %s provided', dir)
      return
    else
      project.new(dir, true)
    end
  end, {
    desc = 'cd into existing/newly made project directory',
    nargs = 1,
    complete = 'dir'
  })

  command.new('ProjectAdd', function(args, _)
    args = trim(args)

    if not fs.is_dir(args) then
      printf("%s is not a directory", args)
      return
    end

    local marker = fs.join(args, ".PROJECT")
    if not fs.is_file(marker) then
      vim.system({ 'touch', marker })
    end

    project.add(args)
  end, {
    desc = 'Mark directory as project',
    complete = 'dir',
    nargs = 1
  })

  command.new('ProjectAddBuffer', function(args, _)
    for i = 1, #args do
      local buf = args[i]
      if string.match(buf, '^[0-9]+$') then
        buf = tonumber(buf)
        if bufnr(buf) == -1 then
          local wd = project.find(buf)
          if wd then project.add(wd, buf) end
        end
      else
        printf("%s is not a valid buffer", tostring(buf))
      end
    end
  end, {
    desc = 'Add project directories of buffers',
    nargs = '+',
    split = '%s+',
    complete = 'buffer',
    process = function(buf)
      if buf == '%' then return vim.fn.bufnr() end
      return buf
    end,
  })

  command.new('ProjectRefresh', function(_, _)
    project.refresh()
  end, {
    desc = 'Fix project directories',
    nargs = 0,
  })
end

function project.setup_autocmds()
  autocmd.new('BufEnter', function(buf, _)
    local proj = project.find_by_buffer(buf)
    if not proj then
      return
    end

    project.track(proj, buf)
    project.cd(proj)
  end, {
    desc = 'cd into project directory',
    pattern = '*.*'
  })

  autocmd.new('BufReadPost', function(_, _)
    project.refresh()
  end, {
    desc = 'Refresh projects',
    pattern = '*.*'
  })
end

---@param dirname string
---@param cd? boolean
---@return boolean
function project.new(dirname, cd)
  if not fs.is_dir(dirname) then
    local ok, msg = pcall(vim.system, { 'mkdir', '-p', dirname })
    if not ok then
      error(msg)
    end
  end

  local marker = fs.join(dirname, '.PROJECT')
  local ok, msg = pcall(vim.system, { 'touch', marker })

  if not ok then
    error(msg)
  end

  if cd then
    vim.fn.chdir(dirname)
  end

  return true
end

function project.setup()
  project.setup_autocmds()
  project.setup_commands()
end

return project
