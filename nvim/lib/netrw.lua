local lib = package.user.lib
local netrw = {}

vim.g.netrw_localcopydircmd = "cp -r"
vim.g.netrw_winsize = 30
vim.g.netrw_winfixheight = 30

function netrw.make_kbd_opts(opts)
  opts = is.str(opts) and {desc = opts} or opts or {}
  opts = copy(opts)
  opts.event = 'Filetype'
  opts.pattern = 'netrw'
  opts.remap = false
  return opts
end

---@return str[]
function netrw.selections()
	local marked = vim.fn["netrw#Expose"]("netrwmarkfilelist")
	if type(marked) == "table" and #marked > 0 then
		return marked
	end

	local cursor_file = netrw.selection()
	if cursor_file ~= "" then
		local curdir = vim.b.netrw_curdir or vim.fn.getcwd()
		return { curdir .. "/" .. cursor_file }
	end

	return {}
end

---@return str?
function netrw.selection()
	local path = vim.fn.expand("<cfile>")
	if path == "" or path == "../" or path == "./" then
		return
	else
		return path
	end
end

function netrw.map1(mode, lhs, opts)
	return function(cb)
		lib.kbd.map(mode, lhs, function()
			local sel = netrw.selection()
			if sel then
				cb(sel)
			else
				print("Nothing selected")
			end
		end, netrw.make_kbd_opts(opts))
	end
end

function netrw.map(mode, lhs, opts)
	return function(cb)
		lib.kbd.map(mode, lhs, function()
			local sels = netrw.selections()
			if #sels == 0 then
				print("Nothing selected")
			else
				lib.list.each(sels, cb)
			end
		end, netrw.make_kbd_opts(opts))
	end
end

function netrw.mapc(mode, lhs, rhs, opts)
	lib.kbd.map(mode, lhs, rhs, netrw.make_kbd_opts(opts))
end

-- Find a window containing an empty buffer (unnamed, unmodified)
function netrw.find_empty_window()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		local modified = vim.bo[buf].modified
		if name == "" and not modified then
			return win
		end
	end
end

lib.netrw = netrw
return lib
