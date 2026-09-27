home:
{ env, pkgs }:
let
  nvimDir = env.MY_NVIM_DIR;
  initVimFile = "${nvimDir}/configuration.vim";
  luaPath = "${nvimDir}/?.lua;${nvimDir}/?/?.lua;${nvimDir}/?/init.lua";
  sourceFile = "${env.MY_INCLUDE_DIR}/setup-neovim.lua";
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
      if not string.match(package.path, ";" .. "${luaPath}") then
        package.path = package.path .. ';' .. "${luaPath}"
      end

      ${builtins.readFile sourceFile}

      vim.g.tagbar_ctags_bin = "${pkgs.ctags}" 
      vim.cmd.source "${initVimFile}"
      vim.cmd.colorscheme "catppuccin"

      _G.LIB = package.user.lib --- @diagnostic disable-line
      _G.USER = package.user --- @diagnostic disable-line

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
