require 'lib.buffer'
require 'lib.project'
require 'lib.keymap'

local lib = package.user.lib
local buffer = lib.buffer
local map = lib.kbd.map
local fs = lib.fs
local neotree = {}
local project = lib.project

---@param dirname string 
function neotree.open(dirname)
  assert(fs.is_dir(dirname), 'Invalid directory ' .. dirname)
  vim.cmd("Neotree bottom filesystem " .. dirname)
end

---@param buf? integer
---@param dir_type? string Any of '[p]roject' or '[d]irectory' (default: 'd')
---@return boolean
function neotree.buf_open(buf, dir_type)
  dir_type = dir_type or 'd'
  local prefix = string.sub(dir_type, 1, 1)
  local is_dir = prefix == 'd'
  buf = buf or buffer.current()
  local dir = not is_dir and project.bfind(buf) or buffer.dirname(buf)

  if not fs.is_dir(dir) then
    return false
  end

  neotree.open(dir)
  return true
end

---@param buf? integer
---@return boolean
function neotree.buf_open_dir(buf)
  return neotree.buf_open(buf, 'd')
end

---@param buf? integer
---@return boolean
function neotree.buf_open_project(buf)
  return neotree.buf_open(buf, 'p')
end

function neotree.setup()
  map('n', '<leader>bd', neotree.buf_open_dir, {desc = 'Explore buffer directory'})
  map('n', '<leader>b.', neotree.buf_open_project, {desc = 'Explore buffer project directory'})
  map('n', '<C-z>', neotree.focus, {desc = 'Focus on currently opened neotree window'})
  map('n', '<M-z>', neotree.toggle, {desc = 'Toggle neotree window'})
  map('n', '~', neotree.toggle, {desc = 'Toggle neotree window'})
end

---@param tabpage? integer
---@return integer?
function neotree.is_open(tabpage)
  tabpage = tabpage or vim.api.nvim_get_current_tabpage()
  local wins = vim.api.nvim_tabpage_list_wins(tabpage)

  for i=1, #wins do
    local winid = wins[i]
    local buf = vim.api.nvim_win_get_buf(winid)
    local ft = vim.bo[buf].filetype

    if ft == 'neo-tree' then
      return winid
    end
  end
end

---@param tabpage? integer
function neotree.focus(tabpage)
  local winid = neotree.is_open(tabpage)
  if winid then
    vim.api.nvim_set_current_win(winid)
    return winid
  end
end

---@param tabpage? integer
---@return integer?
function neotree.hide(tabpage)
  local winid = neotree.is_open(tabpage)
  if winid then
    vim.api.nvim_win_close(winid, true)
    return winid
  end
end

---@param tabpage? integer
function neotree.toggle(tabpage)
  if neotree.is_open(tabpage) then
    neotree.hide(tabpage)
  else
    vim.cmd 'Neotree bottom'
  end
end

lib.neotree = neotree
