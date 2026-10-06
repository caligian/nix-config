home:
{ env, pkgs }:
let
  nvimDir = env.MY_NVIM_DIR;
  initVimFile = "${nvimDir}/configuration.vim";
  luaPath = "${nvimDir}/?.lua;${nvimDir}/?/?.lua;${nvimDir}/?/init.lua";
  sourceFile = "${env.MY_INCLUDE_DIR}/setup-neovim.lua";
  luaPkgs = import <my/pkgs/luajit/common.nix> home { inherit pkgs; };
  mkNeovim = spec: pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped spec;
  myNeovim = mkNeovim {
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
      lsp-format-nvim
    ];
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

      ${builtins.readFile sourceFile}

      vim.g.tagbar_ctags_bin = "${pkgs.ctags}" 
      vim.cmd.source "${initVimFile}"
      vim.cmd.colorscheme "catppuccin"

      --- Contains all the user configurations and state for neovim
      ---@class package.user
      package.user = package.user or {}

      ---Contains all the user configurations
      ---@class package.user.config
      package.user.config = package.user.config or {}

      ---Contains all the user libraries
      ---@class package.user.lib
      package.user.lib = package.user.lib or {}

      ---Contains all the user state
      ---@class package.user.state
      package.user.state = package.user.state or {}

      ---@type package.user.config
      _G.CONFIG = package.user.config

      ---@type package.user.state
      _G.STATE = package.user.state

      ---@type package.user.lib
      _G.LIB = package.user.lib

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
