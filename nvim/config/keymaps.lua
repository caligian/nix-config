require("lib.neotree-filesystem")
require("lib.keymap")
require("lib.project")
require("lib.buffer")

local lib = package.user.lib
local buffer = lib.buffer
local fs = lib.fs
local project = lib.project
local feedkeys = vim.api.nvim_feedkeys
local replace_termcodes = vim.api.nvim_replace_termcodes
local map = lib.kbd.map

vim.g.mapleader = " "
vim.g.maplocalleader = "<C-x>"

local function insert_tab()
	local tab = replace_termcodes("<Tab>", true, false, true)
	feedkeys(tab, "n", false)
end

--- Emacs mappings
map("n", "<C-y>", '"+p', { desc = "Paste from clipboard" })
map("n", "<M-q>", "gqq", { desc = "Wrap lines" })
map("n", "<C-x>q", ":qall!<CR>", { desc = "Quit neovim without saving" })
map("n", "<C-x>x", ":xa<CR>", { desc = "Quit neovim" })
map("n", "<C-g>", ":noh<CR>", { desc = "Disable highlight" })
map("n", "<A-x>", ":Telescope commands<CR>", { desc = "Telescope commands" })
map("v", "<M-q>", "gq", { desc = "Wrap lines" })
map("v", "<M-w>", '"+y', { desc = "Copy to clipboard" })
map("v", "<A-x>", ":", { desc = "Telescope commands" })
map("i", "<A-x>", "<C-o>:'<,'>", { desc = "Run command on range" })
map("i", "<C-a>", "<Home>", { desc = "Start of line" })
map("i", "<C-e>", "<End>", { desc = "End of line" })
map("i", "<C-b>", "<Left>", { desc = "Goto character on left" })
map("i", "<C-f>", "<Right>", { desc = "Goto character on right" })
map("i", "<M-b>", "<C-o>B", { desc = "Goto previous word" })
map("i", "<M-f>", "<C-o>W", { desc = "Goto next word" })
map("i", "<C-p>", "<Up>", { desc = "Goto line above" })
map("i", "<C-n>", "<Down>", { desc = "Goto line below" })
map("i", "<C-d>", "<Del>", { desc = "Delete character backwards" })
map("i", "<M-d>", "<C-o>dW", { desc = "Delete word forwards" })
map("i", "<M-BS>", "<C-o>db", { desc = "Delete word backwards" })
map("i", "<M-k>", "<C-o>d$", { desc = "Delete everything from cursor to EOL" })
map("i", "<M-q>", "<C-o>gqq", { desc = "Wrap lines" })
map("i", "<C-y>", '<C-o>"+p', { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-o>v", { desc = "Start visual mode" })
map("i", "<C-M-i>", insert_tab, { desc = "Insert indentation" })

--- Window management
map("n", "<leader>ws", "<C-w><C-s>", { desc = "Split window horizontally" })
map("n", "<leader>wv", "<C-w><C-v>", { desc = "Split window verticallyy" })
map("n", "<leader>wo", "<C-w><C-o>", { desc = "Hide other windows" })
map("n", "<leader>wj", "<C-w><C-j>", { desc = "Go to window below" })
map("n", "<leader>wk", "<C-w><C-k>", { desc = "Go to window above" })
map("n", "<leader>wh", "<C-w><C-h>", { desc = "Go to window on left" })
map("n", "<leader>wl", "<C-w><C-l>", { desc = "Go to window on right" })
map("n", "<leader>wt", "<C-w>T", { desc = "Break out window into new tab" })

--- Tab management
map("n", "<leader>tt", ":tabnew<CR>", { desc = "Open a new tab" })
map("n", "<leader>tn", ":tabnext<CR>", { desc = "Go to next tab" })
map("n", "<leader>tp", ":tabprev<CR>", { desc = "Go to previous tab" })
map("n", "<leader>tk", ":tabclose<CR>", { desc = "Close current tab" })
map("n", "<leader>1", "1gt", { desc = "Go to tab 1" })
map("n", "<leader>2", "2gt", { desc = "Go to tab 2" })
map("n", "<leader>3", "3gt", { desc = "Go to tab 3" })
map("n", "<leader>4", "4gt", { desc = "Go to tab 4" })
map("n", "<leader>5", "5gt", { desc = "Go to tab 5" })

-- Buffer management
map("n", "<leader>bs", ":w! ")
map("n", "<leader>bS", "SudaWrite %<CR>", { desc = "sudo write buffer" })
map("n", "<leader>br", ":set nomodifiable<CR>", { desc = "RO" })
map("n", "<leader>bR", ":set modifiable<CR>", { desc = "RW" })
map("n", "<leader>by", ":! cat % <bar> wl-copy<CR>", { desc = "Copy buffer" })
map("n", "<leader>bp", ":bprev<CR>", { desc = "Previous buffer" })
map("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bk", ":call HideWindowIfPossible()<CR>", { desc = "Hide buffer" })
map("n", "<leader>bq", ":call DeleteBufferWindowIfPossible()<CR>", { desc = "Delete buffer window" })
map("n", "<leader>bb", ":Telescope buffers<CR>", { desc = "Pick buffers" })
map("n", "<leader>bo", "<cmd>Outline<CR>", { desc = "Toggle Outline" })

-- Lsp operations
map("n", "<leader>lr", ":Telescope lsp_references<CR>", { desc = "LSP references" })
map("n", "<leader>lR", ":lsp restart<CR>", { desc = "(re)Start LSP" })
map("n", "<leader>lq", ":lsp disable<CR>", { desc = "Stop LSP" })
map("n", "<leader>ll", ":lsp enable<CR>", { desc = "Start LSP" })

--- File operations
map("n", "<leader>fs", ":w! %<CR>", { desc = "Save file" })
map("n", "<leader>fS", ":SudaWrite %<CR>", { desc = "Sudo write file" })
map("n", "<leader>fR", ":SudaRead ", { desc = "Sudo read file" })
map("n", "<leader>fg", ":Telescope git_files<CR>", { desc = "git ls-files" })
map("n", "<leader>fr", ":Telescope oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>ff", ":Telescope file_browser<CR>", { desc = "Telescope file browser" })

--- Git operations
map("n", "<leader>gg", ":botright Git<CR>", { desc = "Git browser" })
map("n", "<leader>gb", ":botright Git branch <bar> resize -5<CR>", { desc = "Git branches" })
map("n", "<leader>gl", ":botright Git log <bar> resize -5<CR>", { desc = "Show git log" })
map("n", "<leader>g?", ":botright Git status<CR>", { desc = "Git status" })
map("n", "<leader>gs", ":Git stage %<CR>", { desc = "Stage current buffer" })
map("n", "<leader>gf", ":Telescope git_files<CR>", { desc = "List tracked files" })

--- Misc
map("n", '<leader>"', ":Telescope registers<CR>", { desc = "Telescope registers" })
map("n", "<leader>/", ":Telescope grep_string<CR>", { desc = "Grep current workspace" })
map("n", "<leader>?", ":Telescope live_grep<CR>", { desc = "Live grep workspace" })
map("n", "<leader>'", ":Telescope marks<CR>", { desc = "Telescope marks" })
map("n", "<leader><leader>", ":Telescope resume<CR>", { desc = "Resume picker" })
map("n", "<leader>j", ":Telescope jumplist<CR>", { desc = "Telescope jumplist" })
map("n", "<leader>u", ":UndotreeToggle<CR>", { desc = "Telescope jumplist" })

--- Inspect
map("n", "<leader>hc", ":Telescope colorscheme<CR>", { desc = "Telescope themes" })
map("n", "<leader>ho", ":Telescope vim_options<CR>", { desc = "Telescope vim options" })
map("n", "<leader>hk", ":Telescope keymaps<CR>", { desc = "Telescope keymaps" })
map("n", "<leader>ha", ":Telescope autocommands<CR>", { desc = "Telescope autocmds" })
map("n", "<leader>hp", ":Telescope pickers<CR>", { desc = "Telescope pickers" })
map("n", "<leader>hr", ":Telescope registers<CR>", { desc = "Telescope registers" })
map("n", "<leader>hj", ":Telescope jumplist<CR>", { desc = "Telescope jumplist" })
map("n", "<leader>h:", ":Telescope command_history<CR>", { desc = "Telescope command history" })

--- Terminal keybindings
map("t", "<esc>", "<C-\\><C-n>", { desc = "Normal mode" })

--- Simple diagnostics stuff
package.user.lib.diagnostics = {}
local diagnostics = package.user.lib.diagnostics

---@param dtype? "d" | "p" | "b" (default: "b")
---@return function
function diagnostics.toggle(dtype)
	dtype = dtype or "b"
	return function()
		local f = require("telescope.builtin").diagnostics
		local bufnr = 0

		if not fs.is_file(buffer.get_name(bufnr)) then
			return
		elseif dtype == "b" then
			f({ bufnr = 0 })
		elseif dtype == "d" then
			f({ root_dir = buffer.dirname(bufnr) })
		else
			local proj = project.bfind(bufnr)
			if proj then
				f({ root_dir = proj })
			end
		end
	end
end

function diagnostics.disable(bufnr)
	vim.diagnostic.enable(false, { bufnr = bufnr or 0 })
end

function diagnostics.enable(bufnr)
	vim.diagnostic.enable(true, { bufnr = bufnr or 0 })
end

map("n", "<leader>db", diagnostics.toggle("b"), { desc = "Show diagnostics for buffer" })
map("n", "<leader>dd", diagnostics.toggle("d"), { desc = "Show diagnostics for buffer directory" })
map("n", "<leader>dp", diagnostics.toggle("p"), { desc = "Show diagnostics for buffer project" })
map("n", "<leader>dk", diagnostics.disable, { desc = "Disable diagnostics for buffer" })
map("n", "<leader>de", diagnostics.enable, { desc = "Enable diagnostics for buffer" })
