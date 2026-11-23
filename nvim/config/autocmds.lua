require("lib.buffer")
require("lib.autocmd")

local lib = package.user.lib
local state = package.user.state
local map = lib.autocmd.new
local buffer = lib.buffer
local fs = lib.fs

map("VimLeave", function(_)
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
			if fs.is_file(state.tempfiles[i]) then
				fs.rm(state.tempfiles[i])
			end
		end
	end
end, {
	desc = "Exit cleanup",
	pattern = "*",
})

map("WinEnter", function(_, args)
	if args.match:match("^term://") then
		vim.wo.number = false
		vim.wo.relativenumber = false
	end
end, {
	desc = "Disable number column",
	pattern = "*",
})

map("BufEnter", function(_, args)
	local bufname = args.match
	if not fs.is_file(bufname) then
		return
	end

	local dir = fs.dirname(bufname)
	local dir_history = package.user.state.dir_history

	if not dir_history[dir] then
		dir_history[#dir_history + 1] = dir
		dir_history[dir] = true
	end
end, {
	desc = "Track current buffer directory",
	pattern = "*",
})
