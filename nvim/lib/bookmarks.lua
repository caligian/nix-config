require("lib.keymap")
require("lib.picker")

local lib = package.user.lib
local fs = lib.fs
local dict = lib.dict
local list = lib.list
local buffer = lib.buffer

--- Bookmark stuff
local bookmark = { file = paste0(vim.env.HOME, "/bookmarks.json") }
lib.bookmark = bookmark

function bookmark.load()
	if fs.is_file(bookmark.file) then
		package.user.state.bookmarks = vim.json.decode(fs.slurp(bookmark.file))
	end
end

---@param file? str|int
---@return boolean
function bookmark.add(file)
  file = file or buffer.current()
	if is.num(file) then
		if vim.fn.bufexists(file) == 0 then
			errorf("Invalid buffer: %d", file)
		else
			file = vim.fn.bufname(file)
		end
	end

	if not fs.is_file(file) and not fs.is_dir(file) then
		return false
	else
		vim.cmd(paste(':! bookmark --add "%:p"'))
		return true
	end
end

function bookmark.list()
	vim.cmd(":! bookmark --list")
end

function bookmark.get()
	bookmark.load()
	local paths = dict.keys(package.user.state.bookmarks)
	return list.filter(paths, function(p)
		return is.str(p) and is.path(p)
	end)
end

function bookmark.open()
	local bookmarks = bookmark.get()
	lib.select("Open bookmark", bookmarks, function(entry)
		entry = entry[1]
		if not entry then
			return
		end

		local target = entry.value
		if target:match("^https?://") then
			vim.ui.open(target)
			return
		end

		local path = vim.fn.expand(target)
		if vim.fn.isdirectory(path) == 1 then
			vim.cmd.edit(vim.fn.fnameescape(path))
			return
		end

		local ft = vim.filetype.match({ filename = path })
		if ft and ft ~= "" then
			vim.cmd.edit(vim.fn.fnameescape(path))
			return
		end

		local mime = vim.fn.system({ "file", "--mime-type", "-b", path }):gsub("%s+", "")
		if mime:match("^text/") or mime == "application/json" or mime == "application/xml" then
			vim.cmd.edit(vim.fn.fnameescape(path))
			return
		end

		vim.ui.open(path)
	end)
end

function bookmark.setup()
	local map = lib.kbd.map
	map("n", "<C-x>bb", bookmark.open, { desc = "Explore bookmarks" })
	map("n", "<C-x>bl", bookmark.list, { desc = "List bookmarks" })
	map("n", "<C-x>ba", bookmark.add, { desc = "Add buffer file to bookmarks" })
	map("n", "<C-x>bA", function()
		local buf = buffer.current()
		local file = buffer.get_name(buf)
		if fs.is_file(file) then
			vim.cmd(':! bookmark --add "%:p:h"')
		end
	end, { desc = "Add buffer file to bookmarks" })
end

return lib
