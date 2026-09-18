vim.cmd "let g:suda#prompt = '(sudo)# '"
vim.keymap.set('n', '<space>fS', ':SudaWrite %<CR>', {desc = 'Sudo write'})
