local kbd = vim.keymap.set

vim.cmd [[
  omap     <silent> m :<C-U>lua require('tsht').nodes()<CR>
  xnoremap <silent> m :lua require('tsht').nodes()<CR>
]]

require('nvim-treesitter-textsubjects').configure({
  prev_selection = ',',
  keymaps = {
    ['.'] = 'textsubjects-smart',
    [';'] = 'textsubjects-container-outer',
    ['i;'] = 'textsubjects-container-inner',
  },
})

require('nvim-treesitter.configs').setup {
  sync_install = false,
  auto_install = false,
  ignore_install = { 'tex', 'nix', 'bash', 'r', 'lua', 'python', 'erlang', 'elixir', 'perl' },
  highlight = {
    enable = true,
    disable = {}
  },
  indent = {
    enable = true,
    disable = { 'python' },
  };
  textobjects = {
    move = {
      enable = true,
      set_jumps = true,
    },
    select = {
      enable = true,
      lookahead = true,
      selection_modes = {
        ['@parameter.outer'] = 'v',
        ['@function.outer'] = 'V',
        ['@block.outer'] = '<c-v>',
      },
      include_surrounding_whitespace = true,
    },
  }
}
