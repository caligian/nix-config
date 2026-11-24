require("lib.keymap")

local lib = package.user.lib
local guifont = {}
lib.guifont = guifont

---@return str, int
function guifont.get()
	local font = vim.o.guifont
	local name, height = string.match(font, "^([^:]+):h(%d+)$")
	height = as.num(height)
	---@cast height int
	return name, height
end

---@param name str
---@param height? int
function guifont.set(name, height)
	height = height or 12
	vim.o.guifont = paste0(name, ":h", as.num(height))
	name = string.gsub(name, "%s+", "\\ ")
	vim.cmd(paste0(":set guifont=", name, ":h", as.num(height)))
end

---@param by? int
function guifont.adjust_height(by)
	by = by or 1
	local name, height = guifont.get()
	height = (height or 12) + by
	guifont.set(name, height)
end

---@param by? int
function guifont.inc(by)
	by = by or 1
	by = (by < 0 and (by * -1)) or by
	guifont.adjust_height(by)
end

---@param by? int
function guifont.dec(by)
	by = by or 1
	by = (by > 0 and (by * -1)) or by
	guifont.adjust_height(by)
end

function guifont.setup()
	lib.kbd.map("n", "<C-->", guifont.dec, { desc = "Decrease guifont height" })
	lib.kbd.map("n", "<C-+>", guifont.inc, { desc = "Increase guifont height" })
	lib.kbd.map("n", "<C-=>", guifont.inc, { desc = "Increase guifont height" })
end

return lib
