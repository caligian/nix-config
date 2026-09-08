local fs = require 'lua-utils.fs'
local mapper = require 'lib.keymap'
local project = require 'lib.project'
local bufname = vim.api.nvim_buf_get_name
local map = mapper.map
local opts = { noremap = true }

vim.g.kitty_keyboard_protocol = 1
vim.g.mapleader = " "
vim.g.maplocalleader = "<M-space>"
vim.g.workspaces = {}
vim.g.workspaces_by_buffer = {}

--- Misc stuff
map('n', '<A-x>', ':Telescope commands<CR>', { desc = 'Telescope commands' })
map('i', '<C-a>', '<Home>', opts)
map('i', '<C-e>', '<End>', opts)
map('i', '<C-b>', '<Left>', opts)
map('i', '<C-f>', '<Right>', opts)
map('i', '<M-b>', '<C-o>B', opts)
map('i', '<M-f>', '<C-o>W', opts)
map('i', '<C-p>', '<Up>', opts)
map('i', '<C-n>', '<Down>', opts)
map('i', '<C-d>', '<Del>', opts)
map('i', '<M-d>', '<C-o>dW', opts)
map('i', '<M-BS>', '<C-o>db', opts)
map('i', '<C-u>', '<C-o>d0', opts)
map('i', '<C-_>', '<C-o>u', opts)
map('i', '<M-p>', '<Up>', opts)
map('i', '<M-n>', '<Dovwn>', opts)
map('i', '<M-l>', '<C-o>guw', opts)
map('i', '<M-u>', '<C-o>gUw', opts)
map('n', '<C-g>', ':noh<CR>', { desc = "Disable highlight" })
map('n', '<C-x>q', ':qall!<CR>', { desc = 'Quit neovim without saving' })
map('n', '<C-x>x', ':xa<CR>', { desc = 'Quit neovim' })
map('n', '<leader>"', ':Telescope registers<CR>', { desc = "Telescope registers" })
map('n', '<leader>/', ':Telescope grep_string<CR>', { desc = 'Grep current workspace' })
map('n', '<leader>?', ':Telescope live_grep<CR>', { desc = 'Live grep workspace' })
map('n', '<leader>\'', ':Telescope marks<CR>', { desc = "Telescope marks" })
map('n', '<leader><leader>', ":Telescope resume<CR>", { desc = "Resume picker" })

--- Window management
map('n', '<leader>ws', '<C-w><C-s>', { desc = 'Split window horizontally' })
map('n', '<leader>wv', '<C-w><C-v>', { desc = 'Split window verticallyy' })
map('n', '<leader>wo', '<C-w><C-o>', { desc = 'Hide other windows' })
map('n', '<leader>ws', '<C-w><C-s>', { desc = 'Split window horizontally' })
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
map('n', '<leader>bb', ':Telescope buffers select_current=true<CR>', { desc = 'Show buffers' })
map(
  'n', '<leader>b.',
  ':Telescope buffers cwd_only=true select_current=true<CR>',
  { desc = 'Show working directory buffers' }
)
map(
  'n', '<leader>bd',
  function()
    local buf = vim.fn.bufnr()
    local ok, dir = pcall(fs.dirname, bufname(buf))

    if not ok then
      return
    end

    vim.cmd(':Telescope buffers cwd=' .. dir)
  end
)

-- Lsp operations
map('n', '<leader>ll', ':Telescope lsp_references<CR>', { desc = 'LSP references' })
map('n', '<leader>l?', ':Telescope lsp_definitions<CR>', { desc = 'LSP definitions' })
map('n', '<leader>ls', ':Telescope lsp_document_symbols<CR>', { desc = 'LSP symbols' })
map('n', '<leader>lS', ':Telescope lsp_workspace_symbols<CR>', { desc = 'LSP workspace symbols' })
map('n', '<leader>ld', ':Telescope diagnostics bufnr=0<CR>', { desc = 'LSP diagnostics' })
map('n', '<leader>lD', ':Telescope diagnostics bufnr=0<CR>', { desc = 'LSP workspace diagnostics' })

--- File operations
map('n', '<leader>fs', ':w!<CR>', { desc = 'Save file' })
map('n', '<leader>fS', ':SudaWrite %<CR>', { desc = 'Sudo write file' })
map('n', '<leader>fR', ':SudaRead ', { desc = 'Sudo read file' })
map('n', '<leader>bb', ':Telescope buffers<CR>', { desc = 'Telescope buffers' })
map('n', '<leader>fg', ':Telescope git_files<CR>', { desc = 'git ls-files' })
map('n', '<leader>fr', ':Telescope frecency<CR>', { desc = 'Recent files' })
map(
  'n', '<leader>fd',
  function()
    local buf = vim.fn.bufnr()
    local ok, dir = pcall(fs.dirname, bufname(buf))

    if not ok then
      return
    end

    vim.cmd(':Telescope find_files hidden=true cwd=' .. dir)
  end,
  { desc = 'Telescope buffer directory', }
)
map(
  'n', '<leader>f.',
  function()
    local buf = vim.fn.bufnr()
    local ws = project.find(bufname(buf))

    if not ws then
      return
    end

    vim.cmd(':Telescope find_files follow=true cwd=' .. ws)
  end,
  { desc = 'Telescope project directory' }
)

--- Git operations
map('n', '<leader>gg', ':botright Git<CR>', { desc = 'Git browser' })
map('n', '<leader>gb', ':botright Git branch <bar> resize -5<CR>', { desc = 'Git branches' })
map('n', '<leader>gl', ':botright Git log <bar> resize -5<CR>', { desc = 'Show git log' })
map('n', '<leader>g?', ':botright Git status<CR>', { desc = 'Git status' })
map('n', '<leader>gs', ':Git stage %<CR>', { desc = 'Stage current buffer' })
map('n', '<leader>gf', ':Telescope git_files<CR>', { desc = 'List tracked files' })
