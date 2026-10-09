local kbd = vim.keymap.set
local au = vim.api.nvim_create_autocmd
local home = os.getenv("HOME")
local enable = function(name, config)
  vim.lsp.config(name, config)
  if name ~= '*' then vim.lsp.enable(name) end
end

vim.diagnostic.config {
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.INFO] = "I",
      [vim.diagnostic.severity.HINT] = "H",
    }
  }
}

require('lsp-format').setup {}

require('outline').setup {}

require('neo-tree').setup {
  close_if_last_window = false,
  enable_git_status = false,
  enable_diagnostics = false,
  sources = { "filesystem", "buffers", },
  document_symbols = {
    follow_cursor = true,
    auto_close = false,
  },
  filesystem = {
    hijack_netrw_behavior = "disabled",
    follow_current_file = {
      enabled = true,
      leave_dirs_open = false,
    },
  },
  window = {
    mappings = {
      ['<C-r>'] = 'noop',
    },
  },
  event_handlers = {
    {
      event = 'neo_tree_buffer_enter',
      handler = function()
        local buf = vim.fn.bufnr()
        local winid = vim.fn.bufwinid(buf)

        if winid ~= -1 then
          vim.wo[winid].number = true
          vim.wo[winid].relativenumber = true
        end
      end
    },
    {
      event = 'after_render',
      handler = function(args)
        vim.wo[args.winid].number = true
        vim.wo[args.winid].relativenumber = true
      end
    },
    {
      event = 'neo_tree_window_after_open',
      handler = function(args)
        vim.wo[args.winid].number = true
        vim.wo[args.winid].relativenumber = true
      end
    }
  },
}

au('Filetype', {
  pattern = 'neo-tree',
  callback = function(_)
    local buf = _.buf
    local winid = vim.fn.bufwinid(buf)

    if winid ~= -1 then
      vim.wo[winid].number = true
      vim.wo[winid].relativenumber = true
    end
  end
})

au('WinEnter', {
  pattern = '*',
  callback = function(_)
    if vim.bo.filetype:match 'neo-tree' then
      local buf = _.buf
      local winid = vim.fn.bufwinid(buf)

      if winid ~= -1 then
        vim.wo[winid].number = true
        vim.wo[winid].relativenumber = true
      end
    end
  end
})

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
      hint = { enable = true, semicolon = 'Enable' },
      runtime = { version = 'LuaJIT' },
      diagnostics = {
        globals = { "vim", 'NIL', "GUARD", 'CONFIG', 'STATE' },
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
          string.format("%s/lib/lua/5.1", vim.env.MY_LUAJIT_LIB_DIR),
          string.format("%s/lib", vim.env.MY_NVIM_DIR),
          vim.fn.expand("$HOME/Repos/nvim-utils/nvim-utils"),
          vim.fn.expand("$HOME/Repos/lua-utils/lua-utils"),
          vim.fn.expand("$HOME/Repos/nvim-utils"),
          vim.fn.expand("$HOME/Repos/lua-utils"),
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

enable('perlnavigator', {
  cmd = { 'perlnavigator' },
  filetypes = { 'perl' },
  root_markers = { '.PROJECT' },
  settings = {
    perlnavigator = {
      enableWarnings = true,
      perlPath = "perl",
      perlcriticEnabled = true,
      perlcriticProfile = "",
      perltidyProfile = os.getenv("HOME") .. "/.perltidyrc",
    }
  }
})

if not vim.g.loaded_trouble then
  require('trouble').setup {
    win = {
      position = 'left',
      size = 0.3,
    }
  }
  vim.g.loaded_trouble = true
end

au('LspAttach', {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
    require("lsp-format").on_attach(client, args.buf)
  end,
})

kbd(
  'n',
  '<leader>ld',
  '<cmd>Trouble diagnostics toggle focus=false filter.buf=0<CR>',
  { desc = 'Show diagnostics' }
)

kbd(
  'n',
  '<leader>lD',
  '<cmd>Trouble diagnostics toggle focus=false<CR>',
  { desc = 'Show diagnostics' }
)
