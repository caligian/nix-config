require 'lua-utils.string'

local bufnr = vim.fn.bufnr
local fs = require 'lua-utils.fs'
local types = require 'lua-utils.type'
local autocmd = require 'lib.autocmd'
local command = require 'lib.command'
local bufname = vim.api.nvim_buf_get_name
user_config = user_config or {}
user_config.state = user_config.state or {}

---@class state.workspace
---@field dir {[string]: boolean}
---@field buffer {[number]: string}
---@field check_depth integer
user_config.state.workspace = user_config.state.workspace or {
  dir = {},
  buffer = {},
  check_depth = 4,
  setup_done = false,
}

local project = {}

---@param path string
---@param ... number
function project.add(path, ...)
  user_config.state.workspace.dir[path] = true
  for _, buf in ipairs({ ... }) do user_config.state.workspace.buffer[buf] = path end
end

---@param dir string
---@param buf integer
---@return boolean
function project.has_buffer(dir, buf)
  if user_config.state.workspace.dir[dir] then
    return user_config.state.workspace.buffer[buf] == dir
  else
    return false
  end
end

---@param path string
---@return boolean
function project.is_dir(path)
  return fs.is_dir(path) and fs.is_file(fs.join(path, '.PROJECT'))
end

---@param path string|integer
---@param cd? boolean
---@return string?
function project.find(path, cd)
  local limit = user_config.state.workspace.check_depth
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

  path = type(path) == 'number' and bufname(path) or path
  if path == '' then
    return
  end

  local dir = find(path, 0)
  if dir then
    if cd then vim.fn.chdir(dir) end
    return dir
  end
end

function project.list()
  local res = {}
  for dir, _ in pairs(user_config.state.workspace.dir) do res[#res + 1] = dir end
  return res
end

function project.get_check_depth()
  return user_config.state.workspace.check_depth
end

---@param depth integer
function project.set_check_depth(depth)
  user_config.state.workspace.check_depth = depth
end

function project.refresh()
  local workspaces = user_config.state.workspace.dir or {}
  local workspaces_by_buffer = user_config.state.workspace.buffer or {}

  for workspace, _ in pairs(workspaces) do
    ::next::
    if project.is_dir(workspace) then
      goto next
    end

    local remove = {}
    for buf, ws in pairs(workspaces_by_buffer) do
      if ws == workspace then
        remove[#remove + 1] = buf
      end
    end

    for _, buf in ipairs(remove) do
      workspaces_by_buffer[buf] = nil
    end
  end

  local remove = {}
  for buf, _ in pairs(workspaces_by_buffer) do
    if vim.fn.bufnr(buf) == -1 then
      remove[#remove + 1] = buf
    end
  end

  for _, buf in ipairs(remove) do
    workspaces_by_buffer[buf] = nil
  end
end

function project.setup()
  if user_config.state.workspace.setup_done then
    return
  else
    user_config.state.workspace.setup_done = true
  end

  autocmd.new('BufEnter', function(buf, args)
    local filename = args.match
    local ft = vim.bo.filetype
    local ok = (fs.is_file(filename) or ft ~= '' or string.sub(filename, 1, 1) == '/')

    if not ok then
      return
    end

    local proj = project.find(buf)
    local cd = function(dir) vim.cmd('cd ' .. dir) end

    if proj then
      cd(proj)
      return
    end

    ok, proj = pcall(fs.dirname, filename)
    if not ok then
      return
    end

    cd(proj)
  end, {
    desc = 'cd into project directory',
    pattern = '*.*'
  })

  autocmd.new('BufReadPost', function(_)
    project.refresh()
  end, {
    desc = 'Fix project directories',
    pattern = '*.*'
  })

  command.new('ProjectAddDir', function(args, _)
    args = string.gsub(args, "^~", os.getenv "HOME")
    args = string.trim(args)
    args = string.gsub(args, "/+$", "")

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

return project
