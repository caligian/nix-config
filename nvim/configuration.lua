local current_desktop = os.getenv("XDG_CURRENT_DESKTOP") or ""
local is_sway = os.getenv("SWAYSOCK") ~= nil or string.find(string.lower(current_desktop), "sway") ~= nil

if is_sway then
	vim.g.clipboard = {
		name = "wl-clipboard",
		copy = {
			["+"] = { "wl-copy", "--type", "text/plain" },
			["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
		},
		paste = {
			["+"] = { "wl-paste", "--no-newline", "--type", "text/plain" },
			["*"] = { "wl-paste", "--primary", "--no-newline", "--type", "text/plain" },
		},
		cache_enabled = 1,
	}
else
	vim.g.clipboard = {
		name = "gpaste",
		copy = {
			["+"] = { "gpaste-client" },
			["*"] = { "gpaste-client" },
		},
		paste = {
			["+"] = { "gpaste-client", "--use-index", "get", "0" },
			["*"] = { "gpaste-client", "--use-index", "get", "0" },
		},
		cache_enabled = 1,
	}
end

vim.g.loaded_clipboard_provider = nil
vim.cmd("runtime autoload/provider/clipboard.vim")
vim.opt.clipboard = "unnamed,unnamedplus"

--- Set PATH
local PATH = vim.env.PATH
local ADMIN_BIN_DIR = vim.env.ADMIN_BIN_DIR
local NVIM_BIN_DIR = vim.env.ADMIN_NVIM_DIR .. "/bin"

for _, bin in ipairs({ ADMIN_BIN_DIR, NVIM_BIN_DIR }) do
	if not string.find(PATH, bin, 1, true) then
		vim.env.PATH = vim.env.PATH .. ":" .. bin
	end
end

require("lib")

vim.schedule(function()
	local lib = package.user.lib
	local bufs = vim.api.nvim_list_bufs()

	if #bufs == 1 then
		local buf = lib.buffer.current()
		if vim.bo[buf].filetype == "" then
			vim.cmd.edit(vim.fn.getcwd())
			local bufname = lib.buffer.get_name(buf)
			if bufname == "" then
				lib.buffer.set_name(buf, vim.fn.getcwd())
			end
		end
	end
end)
