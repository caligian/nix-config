local lib = package.user.lib
local fs = lib.fs

require 'lib.project'
require 'lib.command'
require 'lib.buffer'

local project = lib.project
local command = lib.command
local buffer = lib.buffer

local neotree = function(dir)
  vim.cmd(string.format(":Neotree bottom %s", dir))
end

local buffer_opts = {
  nargs = 1,
  filter = function(buf)
    if buf == '0' then
      return true
    end
    return buffer.is_valid(tonumber(buf))
  end,
  process = function(buf)
    if buf == '0' then return vim.fn.bufnr() end
    return tonumber(buf)
  end
}

command.new(
  'BufferProjectBrowse',
  function(buf)
    local proj = project.buf_find(buf)
    if proj then
      neotree(proj)
    end
  end,
  buffer_opts
)

command.new(
  'BufferDirBrowse',
  function(buf)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:sub(1, 1) ~= '/' then
      return
    end

    local dir = fs.dirname(name)
    if fs.is_dir(dir) then
      neotree(dir)
    end
  end,
  buffer_opts
)
