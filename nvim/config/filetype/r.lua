return function(ft)
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
	ft:set_repl_config("R", {})
	ft:set_opts({ shiftwidth = 2, tabstop = 2, expandtab = true })
	ft:set_vars({ r_indent_align_args = 1 })
	ft:map({ "n", "i" }, "<C-M-f>", goto_next_fn, { desc = "Goto next function definition" })
	ft:map({ "n", "i" }, "<C-M-b>", goto_prev_fn, { desc = "Goto previous function definition" })
	ft:map({ "n", "i" }, "<M-f>", goto_next, { desc = "Goto previous definition" })
	ft:map({ "n", "i" }, "<M-b>", goto_prev, { desc = "Goto next definition" })
end
