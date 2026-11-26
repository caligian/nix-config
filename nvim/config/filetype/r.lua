return function(ft)
	local lib = package.user.lib
	local buffer = package.user.lib.buffer
	local find_above = buffer.find_above_and_goto
	local find_below = buffer.find_below_and_goto
	local make_rhs = function(pattern, direction)
		if direction:match("%?") then
			return function()
				find_above(buffer.current(), pattern)
			end
		else
			return function()
				find_below(buffer.current(), pattern)
			end
		end
	end
	local goto_prev_fn = make_rhs("function%(", "?")
	local goto_next_fn = make_rhs("function%(", "/")
	local goto_prev = make_rhs("<%- ", "?")
	local goto_next = make_rhs("<%- ", "/")
	local utils = {
		cmd_goto_prev_function = goto_prev_fn,
		cmd_goto_next_function = goto_next_fn,
		cmd_goto_prev_def = goto_prev_fn,
		cmd_goto_next_def = goto_next_fn,
	}

	---@cast ft filetype
	ft.utils = utils
	ft:set_opts({ shiftwidth = 2, tabstop = 2, expandtab = true })
	ft:set_vars({ r_indent_align_args = 1 })

	ft:map("n", "<leader>rr", function()
		require("r.run").start_R("R")
	end, "R.nvim: Start R console")

	ft:map("n", "<leader>rs", function()
		require("r.run").start_R("R")
	end, "R.nvim: Start / Show R console")

	ft:map("n", "<leader>rk", function()
		local r_buf = vim.g.rplugin and vim.g.rplugin.R_bufnr
		if r_buf then
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				if vim.api.nvim_win_get_buf(win) == r_buf then
					vim.api.nvim_win_close(win, false)
					return
				end
			end
		end
	end, "R.nvim: Hide R console window")

	ft:map("n", "<leader>rq", function()
		require("r.run").quit_R("nosave")
	end, "R.nvim: Quit R console")

	ft:map("n", "<leader>re", function()
		require("r.send").line(false)
	end, "R.nvim: Send line")

	ft:map("v", "<leader>re", function()
		require("r.send").selection(false)
	end, "R.nvim: Send region")

	ft:map("n", "<leader>rb", function()
		require("r.send").source_file("echo")
	end, "R.nvim: Send buffer")

	ft:map({ "n", "i" }, "<C-l>", function()
		require("r.send").cmd("devtools::load_all()")
	end, { desc = "devtools::load_all()" })

	ft:map("n", "<leader>r.", function()
		require("r.send").cmd('setwd("' .. vim.fn.getcwd():gsub("\\", "/") .. '")')
	end, "R.nvim: Set working directory to current cwd")

	ft:map({ "n", "i" }, "<C-M-f>", goto_next_fn, { desc = "Goto next function definition" })
	ft:map({ "n", "i" }, "<C-M-b>", goto_prev_fn, { desc = "Goto previous function definition" })
	ft:map({ "n", "i" }, "<M-f>", goto_next, { desc = "Goto previous definition" })
	ft:map({ "n", "i" }, "<M-b>", goto_prev, { desc = "Goto next definition" })
end
