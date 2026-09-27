local fs = require 'lua-utils.fs'
local mapper = require 'lib.keymap'
local project = require 'lib.project'
local map = mapper.map
local feedkeys = vim.api.nvim_feedkeys
local replace_termcodes = vim.api.nvim_replace_termcodes

vim.g.kitty_keyboard_protocol = 1
vim.g.mapleader = " "
vim.g.maplocalleader = "<C-c>"

--- Emacs mappings for insert mode
map('n', '<A-x>', ':Telescope commands<CR>', { desc = 'Telescope commands' })
map('v', '<A-x>', ":", { desc = 'Telescope commands' })
map('i', '<A-x>', "<C-o>:'<,'>", { desc = 'Run command on range' })
map('i', '<C-a>', '<Home>', { desc = 'Start of line' })
map('i', '<C-e>', '<End>', { desc = 'End of line' })
map('i', '<C-b>', '<Left>', { desc = 'Goto character on left' })
map('i', '<C-f>', '<Right>', { desc = 'Goto character on right' })
map('i', '<M-b>', '<C-o>B', { desc = 'Goto previous word' })
map('i', '<M-f>', '<C-o>W', { desc = 'Goto next word' })
map('i', '<C-p>', '<Up>', { desc = 'Goto line above' })
map('i', '<C-n>', '<Down>', { desc = 'Goto line below' })
map('i', '<C-d>', '<Del>', { desc = "Delete character backwards" })
map('i', '<M-d>', '<C-o>dW', { desc = 'Delete word forwards' })
map('i', '<M-BS>', '<C-o>db', { desc = 'Delete word backwards' })
map('i', '<M-k>', '<C-o>d$', { desc = 'Delete everything from cursor to EOL' })
map("i", "<C-M-i>", function()
  local tab = replace_termcodes("<Tab>", true, false, true)
  feedkeys(tab, "n", false)
end, { desc = "Insert indentation" })
map({ 'n' }, '<M-q>', 'gqq', { desc = 'Wrap lines' })
map({ 'i' }, '<M-q>', '<C-o>gqq', { desc = 'Wrap lines' })
map({ 'v', }, '<M-q>', 'gq', { desc = 'Wrap lines' })

map('n', '<C-g>', ':noh<CR>', { desc = "Disable highlight" })
map('n', '<C-x>q', ':qall!<CR>', { desc = 'Quit neovim without saving' })
map('n', '<C-x>x', ':xa<CR>', { desc = 'Quit neovim' })
map('v', '<M-w>', '"+y', { desc = 'Copy to clipboard' })
map('i', '<C-y>', '<C-o>"+p', { desc = 'Paste from clipboard' })
map('n', '<C-y>', '"+p', { desc = 'Paste from clipboard' })
map('i', '<C-v>', '<C-o>v', { desc = 'Start visual mode' })

--- Window management
map('n', '<leader>ws', '<C-w><C-s>', { desc = 'Split window horizontally' })
map('n', '<leader>wv', '<C-w><C-v>', { desc = 'Split window verticallyy' })
map('n', '<leader>wo', '<C-w><C-o>', { desc = 'Hide other windows' })
map('n', '<leader>wj', '<C-w><C-j>', { desc = 'Go to window below' })
map('n', '<leader>wk', '<C-w><C-k>', { desc = 'Go to window above' })
map('n', '<leader>wh', '<C-w><C-h>', { desc = 'Go to window on left' })
map('n', '<leader>wl', '<C-w><C-l>', { desc = 'Go to window on right' })
map('n', '<leader>wt', '<C-w>T', { desc = 'Break out window into new tab' })

--- Tab management
map('n', '<leader>tt', ':tabnew<CR>', { desc = 'Open a new tab' })
map('n', '<leader>tn', ':tabnext<CR>', { desc = 'Go to next tab' })
map('n', '<leader>tp', ':tabprev<CR>', { desc = 'Go to previous tab' })
map('n', '<leader>tk', ':tabclose<CR>', { desc = 'Close current tab' })
map('n', '<leader>1', '1gt', { desc = 'Go to tab 1' })
map('n', '<leader>2', '2gt', { desc = 'Go to tab 2' })
map('n', '<leader>3', '3gt', { desc = 'Go to tab 3' })
map('n', '<leader>4', '4gt', { desc = 'Go to tab 4' })
map('n', '<leader>5', '5gt', { desc = 'Go to tab 5' })

-- Project management
map('n', '<leader>pp', ':Telescope project<CR>', { desc = 'Select project' })
map('n', '<leader>pf', ":Neotree bottom filesystem<CR>", { desc = "Project directory" })
map('n', '<leader>pb', ':Neotree bottom buffers<CR>', { desc = 'Project show buffers' })

-- Buffer management
map('n', '<leader>bs', ':w! ')
map('n', '<leader>bS', 'SudaWrite %<CR>', { desc = 'sudo write buffer' })
map('n', '<leader>br', ':set nomodifiable<CR>', { desc = 'RO' })
map('n', '<leader>bR', ':set modifiable<CR>', { desc = 'RW' })
map('n', '<leader>by', ':! cat % <bar> wl-copy<CR>', { desc = 'Copy buffer' })
map('n', '<leader>bp', ':bprev<CR>', { desc = 'Previous buffer' })
map('n', '<leader>bn', ':bnext<CR>', { desc = 'Next buffer' })
map('n', '<leader>bk', ':call HideWindowIfPossible()<CR>', { desc = 'Hide buffer' })
map('n', '<leader>bq', ':call DeleteBufferWindowIfPossible()<CR>', { desc = 'Delete buffer window' })
map('n', '<leader>bb', ':Telescope buffers<CR>', { desc = 'Pick buffers' })

-- Lsp operations
map('n', '<leader>lr', ':Telescope lsp_references<CR>', { desc = 'LSP references' })
map('n', '<leader>ls', ':LspRestart<CR>', { desc = '(re)Start LSP' })
map('n', '<leader>lq', ':LspStop<CR>', { desc = 'Stop LSP' })
map('n', '<leader>li', ':LspInfo<CR>', { desc = 'Show LSP information' })
map('n', '<leader>ll', ':LspLog<CR>', { desc = 'Show LSP log' })
map('n', '<leader>lf', ':Format<CR>', { desc = 'Format buffer using LSP if possible' })
map('n', '<leader>lD', ':Telescope diagnostics<CR>', { desc = 'LSP workspace diagnostics' })
map('n', '<leader>ld', ':Telescope diagnostics bufnr=0<CR>', { desc = 'Current buffer diagnostics' })
map("n", "<C-c>o", "<cmd>Outline<CR>", { desc = "Toggle Outline" })

--- File operations
map('n', '<leader>fs', ':w! %<CR>', { desc = 'Save file' })
map('n', '<leader>fS', ':SudaWrite %<CR>', { desc = 'Sudo write file' })
map('n', '<leader>fR', ':SudaRead ', { desc = 'Sudo read file' })
map('n', '<leader>fg', ':Telescope git_files<CR>', { desc = 'git ls-files' })
map('n', '<leader>fr', ':Telescope frecency<CR>', { desc = 'Recent files' })

map('n', '<C-c>p', function()
  local buf = vim.fn.bufnr()
  local name = vim.api.nvim_buf_get_name(buf)

  if name:sub(1, 1) ~= '/' then
    return
  end

  local proj = project.find_by_buffer(buf)
  if proj then
    vim.cmd(':Neotree filesystem ' .. proj)
  end
end, { desc = 'Browse project directory' })

map('n', '<C-c>d', function()
  local buf = vim.api.nvim_buf_get_name(vim.fn.bufnr())
  if buf:sub(1, 1) ~= '/' then
    return
  end

  local dir = fs.dirname(buf)
  if dir then
    vim.cmd(':Neotree filesystem ' .. dir)
  else
    vim.cmd(':Neotree filesystem ' .. os.getenv("HOME"))
  end
end, { desc = 'Browse buffer directory' })

map('n', '<C-c>.', ':Neotree filesystem<CR>', { desc = 'Browse cwd' })
map('n', '<C-c>~', ':Neotree filesystem ~/<CR>', { desc = 'Browse HOME' })
map('n', '<C-c>b', ':Neotree buffers<CR>', { desc = 'Browse buffers' })
map('n', '<C-c>s', ':Neotree document_symbols<CR>', { desc = 'Browse document symbols' })

--- Git operations
map('n', '<leader>gg', ':botright Git<CR>', { desc = 'Git browser' })
map('n', '<leader>gb', ':botright Git branch <bar> resize -5<CR>', { desc = 'Git branches' })
map('n', '<leader>gl', ':botright Git log <bar> resize -5<CR>', { desc = 'Show git log' })
map('n', '<leader>g?', ':botright Git status<CR>', { desc = 'Git status' })
map('n', '<leader>gs', ':Git stage %<CR>', { desc = 'Stage current buffer' })
map('n', '<leader>gf', ':Telescope git_files<CR>', { desc = 'List tracked files' })

--- Misc stuff
map('n', '<leader>"', ':Telescope registers<CR>', { desc = "Telescope registers" })
map('n', '<leader>/', ':Telescope grep_string<CR>', { desc = 'Grep current workspace' })
map('n', '<leader>?', ':Telescope live_grep<CR>', { desc = 'Live grep workspace' })
map('n', '<leader>\'', ':Telescope marks<CR>', { desc = "Telescope marks" })
map('n', '<leader><leader>', ":Telescope resume<CR>", { desc = "Resume picker" })
map('n', '<leader>j', ':Telescope jumplist<CR>', { desc = 'Telescope jumplist' })
map('n', '<leader>u', ':UndotreeToggle<CR>', { desc = 'Telescope jumplist' })

--- Inspect stuff
map('n', '<leader>hc', ':Telescope colorscheme<CR>', { desc = 'Telescope themes' })
map('n', '<leader>ho', ':Telescope vim_options<CR>', { desc = 'Telescope vim options' })
map('n', '<leader>hk', ':Telescope keymaps<CR>', { desc = 'Telescope keymaps' })
map('n', '<leader>ha', ':Telescope autocommands<CR>', { desc = 'Telescope autocmds' })
map('n', '<leader>hp', ':Telescope pickers<CR>', { desc = 'Telescope pickers' })
map('n', '<leader>hr', ':Telescope registers<CR>', { desc = 'Telescope registers' })
map('n', '<leader>hj', ':Telescope jumplist<CR>', { desc = 'Telescope jumplist' })
map('n', '<leader>h:', ':Telescope command_history<CR>', { desc = 'Telescope command history' })

--- Terminal keybindings
map('t', '<esc>', '<C-\\><C-n>', { desc = 'Normal mode' })
