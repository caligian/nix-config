local lib = package.user.lib
local fs = lib.fs
local project = lib.project
local command = lib.command
local buffer = lib.buffer
local as_fun = command.as_fun
local nvim = lib.nvim

local neotree = function(dir)
	vim.cmd(string.format(":Neotree bottom %s", dir))
end

local function get_dir()
	local buf = buffer.current()
	local file = buffer.filename(buf)
	return fs.is_file(file) and fs.dirname(file) or vim.env.PWD
end

local function get_project()
	local buf = buffer.current()
	local file = buffer.filename(buf)
	return fs.is_file(file) and project.find(file) or vim.env.PWD
end

local buffer_opts = {
	nargs = 1,
	filter = function(buf)
		if buf == "0" then
			return true
		end
		return buffer.is_valid(tonumber(buf))
	end,
	process = function(buf)
		if buf == "0" then
			return vim.fn.bufnr()
		end
		return tonumber(buf)
	end,
}

command("BufferProjectBrowse", function(buf)
	local proj = project.buf_find(buf)
	if proj then
		neotree(proj)
	end
end, buffer_opts)

command("BufferDirBrowse", function(buf)
	local name = vim.api.nvim_buf_get_name(buf)
	if name:sub(1, 1) ~= "/" then
		return
	end

	local dir = fs.dirname(name)
	if fs.is_dir(dir) then
		neotree(dir)
	end
end, buffer_opts)

command("CurrentBufferName", as_fun(':echo expand("%:p")'), { nargs = 0 })
command("CurrentBufferDir", as_fun(':echo expand("%:p:h")'), { nargs = 0 })
command("CurrentBufferProject", function()
	local proj = lib.project.buf_find(0)
	if proj then
		print(proj)
	end
end, { nargs = 0 })
command("CurrentBufferBrowseDir", function()
	vim.cmd(paste0(":tabedit ", get_dir()))
end, { nargs = 0 })
command("CurrentBufferBrowseProject", function()
	vim.cmd(paste0(":tabedit ", get_project()))
end, { nargs = 0 })
command("CurrentBufferDirTouch", function()
	nvim.touch(get_dir())
end, { nargs = 0 })
command("CurrentBufferProjectTouch", function()
	nvim.touch(get_project())
end, { nargs = 0 })
