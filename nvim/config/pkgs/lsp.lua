local kbd = vim.keymap.set
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

kbd("n", "<C-t>", "<cmd>Outline<CR>", { desc = "Toggle Outline" })
kbd('n', '<C-p>', ':Neotree<CR>', { desc = 'Neotree' })

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
        globals = { "vim", "apply", "as_list", "assertf", "assert_type", "assert_unless", "assert_when", "bless", "callable", "defined", "dump", "equals", "errorf", "identity", "inspect", "invert", "is_falsy", "is_truthy", "L", "literal", "partial", "paste", "paste0", "pp", "printf", "readlines", "rpartial", "slurp", "spit", "sprintf", "thread", "undefined", "unless", "unless_falsy", "unless_nil", "unless_truthy", "unpack", "when", "when_falsy", "when_nil", "when_truthy", "writelines", "system", "systemlist", "user_config", "user_state", "basename", "dirname", "buffer", "autocmd", "keymap", "buffer_group", "nvim", "augroup", "filetype", 'class', 'metatable', },
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

--[[
Missing deps
require("nvim-file-operations").setup()
require("outline").setup {
  symbols = { icon_fetcher = function(kind, _, _) return string.format('[%s]', kind) end, }
}
--]]
