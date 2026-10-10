home:
{ env, pkgs }:
let
  trouble-nvim = pkgs.vimUtils.buildVimPlugin {
    pname = "trouble.nvim";
    version = "6f380b8";
    postInstall = "echo 'return {}' > $out/lua/trouble/docs.lua";
    src = pkgs.fetchFromGitHub {
      owner = "folke";
      repo = "trouble.nvim";
      rev = "6f380b8826fb819c752c8fd7daaee9ef96d4c689";
      sha256 = "sha256-Y+BOA4tjefvFHs3A2LtfEVy4Ai1Op64UQROKQJTsYYM=";
    };
    dependencies = (
      with pkgs.vimPlugins;
      [
        lazy-nvim
        snacks-nvim
      ]
    );
  };
  nvimDir = env.MY_NVIM_DIR;
  initVimFile = "${nvimDir}/configuration.vim";
  luaPath = "${nvimDir}/?.lua;${nvimDir}/?/?.lua;${nvimDir}/?/init.lua";
  luaPkgs = import <my/pkgs/luajit/common.nix> home { inherit pkgs; };
  mkNeovim = spec: pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped spec;
  myNeovim = mkNeovim {
    plugins =
      (with pkgs.vimPlugins; [
        lazy-nvim
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
        telescope-frecency-nvim
        telescope-fzf-native-nvim
        telescope-file-browser-nvim
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
        lsp-format-nvim
      ])
      ++ [ trouble-nvim ];
    extraLuaPackages = luaPkgs;
    extraPackages = with pkgs; [
      gcc
      gnumake
      unzip
    ];
    luaRcContent = ''
      if not string.match(package.path, ";" .. "${luaPath}") then
        package.path = package.path .. ';' .. "${luaPath}"
      end

      vim.g.clipboard = {
        name = 'gpaste',
        copy = {
          ['+'] = 'gpaste-client add', 
          ['*'] = 'gpaste-client add',
        },
        paste = {
          ['+'] = 'gpaste-client get --use-index 0',
          ['*'] = 'gpaste-client get --use-index 0',
        },
        cache_enabled = 0,
      }

      vim.opt.clipboard:append("unnamedplus") 
      vim.g.tagbar_ctags_bin = "${pkgs.ctags}" 
      vim.cmd.source "${initVimFile}"
      vim.cmd.colorscheme "catppuccin"

      require('lua-utils')
      require("configuration")
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
