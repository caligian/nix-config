local copy = require 'lua-utils.copy'
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
local shell = require 'lib.shell'

local function normalize_buf(buf)
  if buf == nil then
    return vim.fn.bufnr()
  elseif buf == 0 then
    return vim.fn.bufnr()
  else
    return buf
  end
end

---How to query?
---dict.get(<state>, { <workspace>, <filetype> })
package.user.state.repl = package.user.state.repl or {}

local repl = copy(shell)
