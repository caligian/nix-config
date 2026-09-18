home:
{ env, pkgs }:
let
  nvimDir = env.MY_NVIM_DIR;
  initVimFile = "${nvimDir}/configuration.vim";
  luaPath = "${nvimDir}/?.lua;${nvimDir}/?/?.lua;${nvimDir}/?/init.lua";
  options = "{ tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = true, autoindent = true, autochdir = false, background = 'dark', cursorline = false, wildmenu = true, wildmode = 'longest:full,full', number = true, relativenumber = true, termguicolors = true, clipboard = 'unnamedplus', autoindent = true, }";
  globals = "{ tagbar_ctags_bin = '${pkgs.ctags}' }";
  myNeovim = pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
    plugins = with pkgs.vimPlugins; [
      fugitive
      blink-cmp
      blink-ripgrep-nvim
      luasnip
      LuaSnip-snippets-nvim
      nvim-surround
      friendly-snippets
      comment-nvim
      blink-pairs
      blink-indent
      blink-cmp-spell
      outline-nvim
      lualine-nvim
      blink-cmp-latex
      blink-cmp-dictionary
      gitsigns-nvim
      gitignore-nvim
      lazygit-nvim
      mason-nvim
      neo-tree-nvim
      nui-nvim
      themery-nvim
      snacks-nvim
      telescope-nvim
      telescope-project-nvim
      telescope-ultisnips-nvim
      telescope-frecency-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim
      trouble-nvim
      nvim-treesitter
      nvim-treesitter-sexp
      nvim-treesitter-context
      nvim-treesitter-endwise
      nvim-treesitter-textobjects
      vim-suda
      leap-nvim
      vimtex
      which-key-nvim
      nvim-autopairs
      outline-nvim
      nvim-lspconfig
      nvim-treesitter-textsubjects
      neomodern-nvim
      nightfox-nvim
      tokyonight-nvim
      catppuccin-nvim
      nvim-lsp-file-operations
      nvim-web-devicons
      tagbar
      undotree
      base16-vim
      ultisnips
      lsp-format-nvim
    ];
    extraLuaPackages = with pkgs.luajitPackages; [
      lpeg
      ldoc
      busted
      lpeg_patterns
      inspect
      ansicolors
      luautf8
      luafilesystem
      plenary-nvim
      lua-cjson
      sqlite
      luacheck
      luaposix
    ];
    extraPackages = with pkgs; [
      gcc
      gnumake
      unzip
    ];
    luaRcContent = ''
      for key, value in pairs(${options}) do vim.o[key] = value end
      for key, value in pairs(${globals}) do vim.g[key] = value end

      require("lsp-format").setup {}
      vim.keymap.set('n', '<leader>lf', ':Format<CR>', {desc = "Format buffer"})

      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(args)
          pcall(function()
            local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
            require("lsp-format").on_attach(client, args.buf)
          end)
        end,
      })

      package.path = "${luaPath};" .. package.path
      package.user = {}
      package.user.state = {
        autocmd = {},
        keymap = {},
        terminal = {id = {}, pid = {}},
        filetype = {},
        repl = {},
        workspace = {},
        buffer_group = {},
        buffer = {},
        command = {},
        augroup = {},
      }
      package.user.config = {
        plugins = {
          telescope = {
            defaults = {
              layout_config = { height = 0.3 },
              layout_strategy = 'bottom_pane',
              previewer = false,
            },
            pickers = {
              ['*'] = { previewer = false, },
              oldfiles = { previewer = false, },
              find_files = { previewer = false, },
              git_files = { previewer = false, },
              buffers = {
                show_all_buffers = true,
                sort_lastused = true,
                previewer = false,
                mappings = {
                  i = { ["<c-d>"] = "delete_buffer", },
                  n = { ["dd"] = "delete_buffer", }
                }
              },
              diagnostics = {
                previewer = false,
              }
            },
            extensions = {
              frecency = {
                previewer = false,
              },
              file_browser = {
                previewer = false,
              },
              project = {
                previewer = false,
              }
            }
          }
        },
        workspace = {
          check_depth = 4,
          marker = '.PROJECT',
        },
      }

      _G.STATE = package.user.state
      _G.CONFIG = package.user.config

      vim.cmd ":source ${initVimFile}"
      require 'configuration'
    '';
  };
in
(with pkgs; [
  luajit
  luarocks
  nodejs_22
  nodePackages.npm
  cargo
  rustc
  myNeovim
])
