{
  home,
  pkgs ? import <nixpkgs> { },
}:
let
  nvimDir = "${home}/.user/nvim";
  initVimFile = "${nvimDir}/configuration.vim";
  luaPath = "${nvimDir}/?.lua;${nvimDir}/?/?.lua;${nvimDir}/?/init.lua";
  options = "{ tabstop = 4, shiftwidth = 4, softtabstop = 4, expandtab = true, autoindent = true, autochdir = false, background = 'dark', cursorline = false, wildmenu = true, wildmode = 'longest:full,full', number = true, relativenumber = true, termguicolors = true, clipboard = 'unnamedplus', autoindent = true, }";
  globals = "{ tagbar_ctags_bin = '${pkgs.ctags}' }";
in
pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
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
    ctags
    universal-ctags
    ripgrep
    fd
    tree-sitter
    gcc
    gnumake
    unzip
    git
    p7zip
  ];
  luaRcContent = ''
    for key, value in pairs(${options}) do vim.o[key] = value end
    for key, value in pairs(${globals}) do vim.g[key] = value end

    require("lsp-format").setup {}

    vim.api.nvim_create_autocmd('LspAttach', {
      callback = function(args)
        pcall(function()
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
          require("lsp-format").on_attach(client, args.buf)
        end)
      end,
    })

    package.path = "${luaPath};" .. package.path
    package.plugins = {opts = {}} -- Contains all options used by default by plugins

    vim.cmd ":source ${initVimFile}"
    require 'configuration'
  '';
}
