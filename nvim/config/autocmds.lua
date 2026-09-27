local path = require 'lua-utils.fs'
local buffer = require 'lib.buffer'
local map = require('lib.autocmd').new
local state = package.user.state

map({ "VimLeave" }, function(_)
  for _, term in pairs(state.terminal.id or {}) do
    if term:is_running() then
      term:stop()
    end

    vim.schedule(function()
      if term.buffer and buffer.exists(term.buffer) then
        buffer.wipeout(term.buffer)
      end
    end)

    for i = 1, #state.tempfiles do
      if path.is_file(state.tempfiles[i]) then
        path.rm(state.tempfiles[i])
      end
    end
  end
end, {
  desc = "Exit cleanup",
  pattern = "*",
})
