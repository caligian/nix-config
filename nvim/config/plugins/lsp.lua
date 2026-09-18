local home = os.getenv("HOME")

vim.diagnostic.config({
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    }
  }
})

require('mason').setup {}

require('outline').setup {}

require('neo-tree').setup({
  close_if_last_window = false,
  enable_git_status = true,
  enable_diagnostics = true,
  sources = { "filesystem", "buffers", },
  document_symbols = {
    follow_cursor = true,
    auto_close = false,
  }
})

-- Add default configurations
local function enable(name, config)
  vim.lsp.config(name, config)
  if name ~= '*' then vim.lsp.enable(name) end
end

-- .git will be phased out in favour of .PROJECT
enable('*', { root_markers = { '.PROJECT' }, })

-- python
enable('jedi_language_server', {
  cmd = { 'jedi-language-server' },
  filetypes = { 'python' },
  root_markers = { '.PROJECT' },
  init_options = { workspace = { extraPaths = { home .. "/Repos/common_utils/src", } } },
})

enable('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { '.PROJECT' },
  settings = {},
  init_options = { settings = { configuration = home .. '/ruff.toml', } }
})

enable('lua_lsp', {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { '.PROJECT', },
  settings = {
    Lua = {
      codeLens = { enable = true },
      hint = { enable = true, semicolon = 'Disable' },
      runtime = { version = 'LuaJIT' },
      diagnostics = {
        globals = { "vim", },
        disable = {
          "duplicate-doc-field",
          "duplicate-doc-alias",
          'cast-local-type',
          'missing-fields',
          'lowercase-global',
          'unused-vararg',
          'need-check-nil',
          'assign-type-match',
          'param-type-mismatch',
          'inject-field',
          'redundant-parameter',
        }
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.expand("$HOME/pkgs/lib/luarocks/rocks-5.1"),
          vim.fn.expand("$HOME/Repos/nvim-utils/nvim-utils"),
          vim.fn.expand("$HOME/Repos/lua-utils/lua-utils"),
        },
      },
      telemetry = { enable = false },
    },
  },
})

enable('r_language_server', {
  cmd = { 'R', '--no-echo', '-e', 'languageserver::run()' },
  filetypes = { 'r', 'rmd', 'quarto', },
  root_markers = { '.PROJECT' },
})

enable('nixd', {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git', '.PROJECT' },
})

enable('nil', {
  cmd = { 'nil' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git', '.PROJECT' },
})
