local function get_high_contrast_light_theme()
	if vim.o.background ~= "light" then
		return "auto"
	end

	local black = vim.g.terminal_color_0 or "#1a1a1a"
	local light_gray = vim.g.terminal_color_7 or "#e0e0e0"
	local white = vim.g.terminal_color_15 or "#ffffff"
	local blue = vim.g.terminal_color_4 or "#005faf"
	local green = vim.g.terminal_color_2 or "#008700"
	local purple = vim.g.terminal_color_5 or "#8700af"

	return {
		normal = {
			a = { bg = blue, fg = white, bold = true },
			b = { bg = light_gray, fg = black },
			c = { bg = white, fg = black },
		},
		insert = {
			a = { bg = green, fg = white, bold = true },
			b = { bg = light_gray, fg = black },
			c = { bg = white, fg = black },
		},
		visual = {
			a = { bg = purple, fg = white, bold = true },
			b = { bg = light_gray, fg = black },
			c = { bg = white, fg = black },
		},
		replace = {
			a = { bg = vim.g.terminal_color_1 or "#d70000", fg = white, bold = true },
			b = { bg = light_gray, fg = black },
			c = { bg = white, fg = black },
		},
		inactive = {
			a = { bg = light_gray, fg = black },
			b = { bg = light_gray, fg = black },
			c = { bg = light_gray, fg = black },
		},
	}
end

local lualine = require("lualine").setup
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local lualine_contrast_group = augroup("LualineContrastRefresh", { clear = true })

autocmd("ColorScheme", {
	group = lualine_contrast_group,
	pattern = "*",
	callback = function()
		local current_theme = get_high_contrast_light_theme()
		require("lualine").setup({
			options = {
				theme = current_theme,
			},
		})
	end,
})

lualine({
	options = {
		icons_enabled = false,
		component_separators = { left = "", right = "" },
		section_separators = { left = "", right = "" },
		disabled_filetypes = {
			statusline = {},
			winbar = {},
		},
		ignore_focus = {},
		always_divide_middle = true,
		always_show_tabline = true,
		globalstatus = false,
		refresh = {
			statusline = 1000,
			tabline = 1000,
			winbar = 1000,
			refresh_time = 16, -- ~60fps
			events = {
				"WinEnter",
				"BufEnter",
				"BufWritePost",
				"SessionLoadPost",
				"FileChangedShellPost",
				"VimResized",
				"Filetype",
				"CursorMoved",
				"CursorMovedI",
				"ModeChanged",
			},
		},
	},
	sections = {
		lualine_a = { "mode" },
		lualine_b = { "branch", "diff", "diagnostics" },
		lualine_c = { "filename" },
		lualine_x = { "encoding", "fileformat", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { "filename" },
		lualine_x = { "location" },
		lualine_y = {},
		lualine_z = {},
	},
	tabline = {},
	winbar = {},
	inactive_winbar = {},
	extensions = {},
})
