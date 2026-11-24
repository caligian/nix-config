require("lib.definitions")
require("lib.buffer")

local lib = package.user.lib
local buffer = lib.buffer
local fs = lib.fs
local list = lib.list
local nvim = {}
lib.nvim = nvim

nvim.fnamemodify = vim.fn.fnamemodify
nvim.fname = {}

---@param s string
---@param no_suffix? boolean
---@param as_list? boolean
---@return string
function nvim.fname.expand(s, no_suffix, as_list)
	return vim.fn.expand(s, no_suffix, as_list)
end

function nvim.fname.dirname(file)
	return nvim.fnamemodify(file, "%:p:h")
end

nvim.fname.dir = nvim.fname.dirname

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.abspath(file, rest)
	return nvim.fnamemodify(file, ":p" .. (rest or ""))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.head(file, rest)
	return nvim.fnamemodify(file, ":h" .. (rest or ""))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.extension(file, rest)
	return nvim.fnamemodify(file, ":e" .. (rest or ""))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.root(file, rest)
	return nvim.fnamemodify(file, ":r" .. (rest or ""))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.relpath(file, rest)
	return nvim.fnamemodify(file, ":." .. (rest or ""))
end

---@param file string
---@param rest string Rest of the mods
---@return string
function nvim.fname.relhomepath(file, rest)
	return nvim.fnamemodify(file, ":~" .. (rest or ""))
end

---@param keys string
---@param mode? string
---@param replace_termcodes? boolean
function nvim.feedkeys(keys, mode, replace_termcodes)
	mode = mode or "m"
	replace_termcodes = (replace_termcodes == nil and true) or replace_termcodes
	vim.api.nvim_feedkeys(keys, mode, replace_termcodes)
end

---@param special? boolean
---@return string
function nvim.replace_termcodes(s, special)
	return vim.api.nvim_replace_termcodes(s, true, false, special)
end

---Run ex string with `normal!`
---@param ... string
---@return boolean, string?
function nvim.normal(...)
	for _, cmd in ipairs({ ... }) do
		local ok, msg = pcall(vim.cmd, "normal! " .. nvim.replace_termcodes(cmd))
		if not ok then
			return false, msg
		end
	end

	return true, nil
end

function nvim.noh()
	vim.cmd(":noh")
end

function nvim.goto_next_search()
	nvim.normal("n")
end

function nvim.goto_prev_search()
	nvim.normal("N")
end

---@param as_list? boolean
---@return (string|string[])?
function nvim.region(as_list)
	local esc = nvim.replace_termcodes("<esc>", true, false, true)
	nvim.feedkeys(esc, "x", false)
	local vstart = vim.fn.getpos("'<")
	local vend = vim.fn.getpos("'>")
	local ok, _region = pcall(vim.fn.getregion, vstart, vend, vim.empty_dict())

	if not ok then
		return
	elseif as_list then
		return _region
	else
		return list.concat(_region, "\n")
	end
end

nvim.get_region = nvim.region

nvim.eval = {
	---@param s str
	---@return bool, str?, ...
	string = function(s)
		local fn, msg = loadstring(s)
		if not fn then
			return false, msg, nil
		else
			return true, nil, fn()
		end
	end,

	---@param file str
	---@return bool, str?, ...
	file = function(file)
		fs.assert.is_file(file)
		return nvim.eval.str(fs.slurp(file))
	end,

	region = function()
		local region = nvim.region(false)
		if not region then
			return false, "Could not fetch region", nil
		else
			return nvim.eval.str(region)
		end
	end,
}

nvim.eval.str = nvim.eval.string
nvim.eval.visual = nvim.eval.region
nvim.eval_string = nvim.eval.str
nvim.eval_str = nvim.eval.str
nvim.eval_file = nvim.eval.file
nvim.eval_visual = nvim.eval.visual
nvim.eval_region = nvim.eval.region

function nvim.mode()
	return vim.fn.mode()
end

function nvim.in_visual_mode()
	local mode = nvim.mode()
	return mode == "v" or mode == "V" or mode == ""
end

function nvim.in_normal_mode()
	return nvim.mode() == "n"
end

function nvim.is_file(file)
	return vim.fn.filereadable(file) == 1
end

function nvim.is_dir(file)
	return vim.fn.isdirectory(file) == 1
end

---@param prompt string?
---@param on_input fun(choice: str)
---@param on_nothing? fun()
function nvim.input(prompt, on_input, on_nothing)
	vim.ui.input({ prompt = prompt or "% " }, function(input)
		if not input then
			return
		elseif #input > 0 then
			on_input(input)
		elseif on_nothing then
			on_nothing()
		end
	end)
end

---@param choices str[]
---@param prompt? str (default: "> ")
---@param on_choice fun(item: str, idx: integer?)
---@param formatter? fun(item: any):string
function nvim.select(choices, prompt, on_choice, formatter)
	vim.ui.select(choices, { prompt = prompt, format_item = formatter }, on_choice)
end

---@param ... string
---@return Ok<str>|Err
function nvim.cmd(...)
	local cmd = table.concat({ ... }, "\n")
	local ok, value_or_msg = pcall(vim.api.nvim_exec2, cmd, { output = false })

	if not ok then
		return Err:new(Error:new(value_or_msg), { cmd = cmd })
	else
		return Ok:new(value_or_msg, { cmd = cmd })
	end
end

---@param fmt str
---@param ... str|num
function nvim.cmdf(fmt, ...)
	vim.cmd(string.format(fmt, ...))
end

---@param linenum number
---@return boolean, string?
function nvim.goto_linenum(linenum)
	local ok, msg = nvim.cmd("normal! %dG", linenum)
	if ok then
		return true, nil
	else
		return false, msg
	end
end

---@param cmd string
---@param ... any
function nvim.system(cmd, ...)
	cmd = sprintf(cmd, ...)
	vim.cmd(sprintf(":! %s", cmd))
end

function nvim.setup()
	local mkcommand = vim.api.nvim_create_user_command
	local kbd = vim.keymap.set

	mkcommand("EvalRegion", function()
		nvim.eval.region()
	end, { nargs = 0 })

	mkcommand("EvalFile", function(args)
		nvim.eval.file(args.args)
	end, { nargs = 1, complete = "file" })

	mkcommand("EvalBuffer", function(args)
		local buf = args.fargs[1]
		buf = buf or 0
		buf = is.int(buf) and tonumber(buf) or buf
		local file = vim.api.nvim_buf_get_name(buf)
		fs.assert.is_file(file)
		nvim.eval.file(file)
	end, { nargs = "?", complete = "buffer" })

	kbd("v", "<C-x>ee", "<Cmd>EvalRegion<CR>", { desc = "Eval region in current buffer" })
	kbd("n", "<C-x>eb", ":EvalBuffer 0<CR>", { desc = "Eval current buffer" })
	kbd("n", "<C-x>ef", ":EvalFile ", { desc = "Eval file" })
end

---@param dir? str
function nvim.touch(dir)
	if not dir then
		local bufname = vim.fn.bufname()
		if not fs.is_file(bufname) then
			return
		else
			dir = nvim.fnamemodify(bufname, ":p:h")
		end
	end

	local cmd = vim.cmd
	local prompt = paste0(dir:gsub(os.getenv("HOME"), "~"), "/{PATH} > ")
	local input = vim.ui.input
	local opts = { prompt = prompt, scope = "buffer" }

	input(opts, function(str)
		if not str or #str == 0 then
			print("No directory provided")
			return
		end

		local new_file = fs.join(dir, str)
		local is_dir = new_file:sub(#new_file, #new_file) == "/"

		if not is_dir then
			local new_buf = vim.fn.bufadd(new_file)
			buffer.set_opt(new_buf, "buflisted", true)
		else
			cmd(string.format(':! mkdir -p "%s"', new_file))
		end

		cmd(string.format(':tabedit "%s"', new_file))
	end)
end

function nvim.cabbrev(cmd, abbrev)
	vim.cmd(paste0(":cnoreabbr ", abbrev, " ", cmd))
end

nvim.strftime = vim.fn.strftime
nvim.strptime = vim.fn.strptime
nvim.get_region = nvim.region
nvim.get_mode = nvim.mode
nvim.expand = nvim.fname.expand
nvim.abspath = nvim.fname.abspath
nvim.extension = nvim.fname.extension
nvim.relpath = nvim.fname.relpath
nvim.relhomepath = nvim.fname.relhomepath
nvim.rmtermcodes = nvim.replace_termcodes

package.user.lib.nvim = nvim
package.user.lib.strftime = vim.fn.strftime
package.user.lib.strptime = vim.fn.strptime
package.user.lib.get_region = nvim.region
package.user.lib.get_mode = nvim.mode
package.user.lib.expand = nvim.fname.expand
package.user.lib.abspath = nvim.fname.abspath
package.user.lib.extension = nvim.fname.extension
package.user.lib.relpath = nvim.fname.relpath
package.user.lib.relhomepath = nvim.fname.relhomepath
package.user.lib.fname = nvim.fname
package.user.lib.feedkeys = nvim.feedkeys
package.user.lib.replace_termcodes = nvim.replace_termcodes
package.user.lib.normal = nvim.normal
package.user.lib.noh = nvim.noh
package.user.lib.goto_next_search = nvim.goto_next_search
package.user.lib.goto_prev_search = nvim.goto_prev_search
package.user.lib.region = nvim.region
package.user.lib.eval = nvim.eval
package.user.lib.eval_region = nvim.eval_region
package.user.lib.eval_visual = nvim.eval_visual
package.user.lib.eval_string = nvim.eval_string
package.user.lib.eval_str = nvim.eval_str
package.user.lib.eval_file = nvim.eval_file
package.user.lib.get_mode = nvim.get_mode
package.user.lib.in_visual_mode = nvim.in_visual_mode
package.user.lib.in_normal_mode = nvim.in_normal_mode
package.user.lib.rmtermcodes = nvim.replace_termcodes

return lib
