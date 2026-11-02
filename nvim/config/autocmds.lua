require("lib.buffer")
require("lib.autocmd")

local lib = package.user.lib
local state = package.user.state
local map = lib.autocmd.new
local buffer = lib.buffer
local path = lib.path

for _, spec in ipairs({
	{
		"VimLeave",
		function(_)
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
		end,
		{
			desc = "Exit cleanup",
			pattern = "*",
		},
	},
	{
		"WinEnter",
		function(_, args)
			if args.match:match("^term://") then
				vim.wo.number = false
				vim.wo.relativenumber = false
			end
		end,
		{
			desc = "Disable number column",
			pattern = "*",
		},
	},
}) do
	map(unpack(spec))
end
