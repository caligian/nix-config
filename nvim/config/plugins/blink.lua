require('blink.cmp').setup {
  keymap = {
    preset = 'default',
    ['<Tab>'] = { 'snippet_forward', 'select_next', 'fallback' },
    ['<S-Tab>'] = { 'snippet_backward', 'select_prev', 'fallback' },
    ['<C-h>'] = { 'show_documentation', 'hide_documentation', 'fallback' },
    ['<C-g>'] = { 'hide', 'fallback' },
    ['<CR>'] = { 'accept', 'fallback' },
    ['<C-p>'] = { 'select_prev', 'fallback' },
    ['<C-n>'] = { 'select_next', 'fallback' },
    ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
    ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
    ['<C-s>'] = { 'show_signature', 'hide_signature', 'fallback' },
    ['<C-Space>'] = { 'show', 'fallback' },
  },
  snippets = {
    expand = function(snippet)
      require('luasnip').lsp_expand(snippet)
    end,
    active = function(filter)
      if filter and filter.direction then
        return require('luasnip').jumpable(filter.direction)
      end
      return require('luasnip').in_snippet()
    end,
    jump = function(direction)
      require('luasnip').jump(direction)
    end,
  },
  appearance = { nerd_font_variant = 'mono' },
  completion = {
    accept = { auto_brackets = { enabled = false } },
    documentation = { auto_show = true },
    menu = { auto_show = false },
  },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'buffer', },
    providers = {
      ripgrep = {
        module = "blink-ripgrep",
        name = "Ripgrep",
        opts = {
          project_root_marker = '.git',
          toggles = { on_off = '<leader>sr', debug = nil, },
        }
      }
    }
  },
  fuzzy = { implementation = "rust" },
  signature = { enabled = true, },
}
