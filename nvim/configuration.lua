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

require("lib")
