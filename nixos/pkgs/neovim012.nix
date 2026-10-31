{
  path,
  pkgs,
  ...
}:
let
  luajitPackages = pkgs.luajitPackages;
  buildLuarock = luajitPackages.buildLuarocksPackage;
  patchedLuasystem = luajitPackages.luasystem.overrideAttrs (old: {
    preConfigure = (old.preConfigure or "") + ''
      export RT_DIR=${pkgs.glibc.out}
    '';
  });
  myRocks = {
    lpath = buildLuarock rec {
      pname = "lpath";
      version = "0.4.0-1";
      src = pkgs.fetchFromGitHub {
        owner = "starwing";
        repo = "lpath";
        rev = "cdc573e8bf3fabe67e67a41651de1b2da93f306c";
        hash = "sha256-d1xV0j2vcyyC3+xfp2RWsJs4ChDmAX6feBbY8KdFjYU=";
      };
      knownRockspec =
        (pkgs.fetchurl {
          url = "mirror://luarocks/${pname}-${version}.rockspec";
          sha256 = "sha256-6lMblY3GkvUE27T8Mx6chWGg5A5c5nq5RfbNZET6Dss=";
        }).outPath;
    };
    inspect = pkgs.luajitPackages.buildLuaPackage {
      pname = "inspect";
      version = "a8ca312";
      src = pkgs.fetchFromGitHub {
        owner = "kikito";
        repo = "inspect.lua";
        rev = "a8ca3120dfec48801036eaeff9335ab7a096dd24";
        hash = "sha256-2+voC5OcNuuaSZu0KNK64vtHHxDWr1slejF0ToVeDCI=";
      };
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/lua/5.1
        cp inspect.lua $out/share/lua/5.1/
      '';
    };
  };
  luaPkgs =
    (with pkgs.luajitPackages; [
      busted
      ldoc
      cjson
      luacheck
      luafilesystem
      luautf8
      luv
      penlight
      lpeg
      lpeg_patterns
      ansicolors
      sqlite
      luaposix
    ])
    ++ [
      patchedLuasystem
      myRocks.inspect
      myRocks.lpath
    ];
  nvimPlugins = (
    with pkgs.vimPlugins;
    [
      conform-nvim
      lazy-nvim
      vim-fugitive
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
      neo-tree-nvim
      nui-nvim
      themery-nvim

      telescope-nvim
      telescope-project-nvim
      telescope-frecency-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim

      nvim-treesitter
      nvim-treesitter-parsers.lua
      nvim-treesitter-parsers.luadoc
      nvim-treesitter-parsers.python
      nvim-treesitter-parsers.perl
      nvim-treesitter-parsers.bash
      nvim-treesitter-parsers.r
      nvim-treesitter-parsers.nix
      nvim-treesitter-parsers.sql
      nvim-treesitter-endwise
      nvim-treesitter-textobjects

      vim-suda
      leap-nvim
      vimtex
      which-key-nvim
      nvim-autopairs
      nvim-lspconfig

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
    ]
  );
  nvimDir = path.dir.nvim;
  initVimFile = "${nvimDir}/configuration.vim";
  luaPath = "${nvimDir}/?.lua;${nvimDir}/?/?.lua;${nvimDir}/?/init.lua";
  mkNeovim = spec: pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped spec;
  join = builtins.concatStringsSep;
  packagePaths = join ";" (map (p: "${p}/share/lua/5.1/?.lua;${p}/share/lua/5.1/?/init.lua") luaPkgs);
  packageCPaths = join ";" (map (p: "${p}/lib/lua/5.1/?.so") luaPkgs);
  myNeovim = mkNeovim {
    lua = pkgs.luajit;
    plugins = nvimPlugins;
    extraLuaPackages = ps: [ ];
    extraPackages =
      (with pkgs; [
        gcc
        gnumake
        unzip
        ripgrep
        fdfind
      ])
      ++ luaPkgs;
    luaRcContent = ''
      if not string.find(package.path, "${luaPath}", 1, true) then
        package.path = package.path .. ';' .. "${luaPath}"
      end

      package.path = "${packagePaths};" .. package.path
      package.cpath = "${packageCPaths};" .. package.cpath

      vim.g.tagbar_ctags_bin = "${pkgs.ctags}/bin/ctags"

      require('conform').setup {
        formatters_by_ft = {
          lua = {'stylua'},
          python = {'isort', 'black'},
          r = {'air'},
          perl = {'perltidy'},
        },
        format_on_save = false,
      }

      local nvim_dir  = "${path.dir.nvim}"
      local user_root = "${path.dir.root}"

      if vim.fn.isdirectory(nvim_dir) == 0 then
        vim.notify("Bootstrapping " .. nvim_dir .. " ...", vim.log.levels.INFO)

        if vim.fn.isdirectory(user_root) == 1 then
          vim.fn.delete(user_root, "rf")
        end

        if vim.fn.isdirectory(user_root .. "/.git") == 0 then
          local out = vim.fn.system({
            "${pkgs.git}/bin/git", "clone", "--depth=1",
            "https://github.com/caligian/nix-config",
            user_root,
          })
          if vim.v.shell_error ~= 0 then
            vim.notify("Clone failed:\n" .. out, vim.log.levels.ERROR)
          end
        else
          local out = vim.fn.system({
            "${pkgs.git}/bin/git", "-C", user_root, "checkout", "--", "nvim",
          })
          if vim.v.shell_error ~= 0 then
            vim.notify("Restore failed:\n" .. out, vim.log.levels.ERROR)
          end
        end
      end

      if vim.fn.isdirectory(nvim_dir) == 1 then
        vim.opt.clipboard:append("unnamedplus")
        vim.cmd.source "${initVimFile}"
        vim.cmd.colorscheme "catppuccin"

        require('lua-utils')
        require("configuration")

        vim.keymap.set("n", "<leader>lf", function()
          require("conform").format({ async = true, lsp_format = "fallback" })
        end, { desc = "Format buffer" })
      else
        vim.notify("Bootstrapping failed. Please clone https://www.github.com/caligian/nix-config to ~/.user manually")
      end
    '';
  };
in
(with pkgs; [
  nodejs_22
  cargo
  rustc
  nil
  nixd
  lua-language-server
  bash-language-server
  texlab
  perlnavigator
  rPackages.languageserver
  python313Packages.jedi-language-server
  perlPackages.PerlTidy
  stylua
  black
  isort
  shellcheck
  shfmt
  air-formatter
])
++ [ myNeovim ]
