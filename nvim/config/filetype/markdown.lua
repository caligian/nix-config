return function(ft)
	local lib = package.user.lib
	local fs = lib.fs
	local buffer = lib.buffer

	local function on(f)
		return function()
			local buf = buffer.current()
			local bufname = buffer.get_name(buf)
			if bufname and fs.is_file(bufname) and vim.bo[buf].filetype == 'markdown' then
				return f(bufname)
			end
		end
	end

	local function convert(file, dst_fmt)
		local outfile = string.format("'%s'", file:gsub("md$", dst_fmt))
		local infile = string.format("'%s'", file)
		local cmd = string.format(":!pandoc --from markdown --to %s %s -o %s ", dst_fmt, infile, outfile)
		vim.cmd(cmd)
	end

	local function cmd(dst_fmt)
		return on(function(file)
			convert(file, dst_fmt)
		end)
	end

	---@cast ft filetype
	ft:map({ "n" }, "<C-c><C-d>", cmd("docx"), { desc = "Compile buffer to docx" })
	ft:map({ "n" }, "<C-c><C-c>", cmd("pdf"), { desc = "Compile buffer to pdf" })

	return ft
end
