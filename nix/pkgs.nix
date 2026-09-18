{
  pkgs ? import <nixpkgs> { },
}:
let
  base = with pkgs; {
    interpreters = [
      python313
      (with python313Packages; [
        jedi-language-server
        python-docx
        termcolor
        pandas
        babel
        ipython
        ipdb
        yt-dlp
        polars
        pycmus
        pyfzf
        numpy
        selenium
      ])
      R
      (with rPackages; [
        languageserver
        tidyverse
        data_table
        ggplot2
        shiny
        lintr
      ])
    ];
    build = [
      gcc
      gnumake
      cmake
      pkg-config
      binutils
      coreutils
    ];
    neovim = [
      luarocks
      luajit
    ];
    IDE = [
      nodejs_22
      nodePackages.npm
      cargo
      rustc
      tree-sitter
    ];
    utils = [
      cmus
      git
      curl
      wget
      unzip
      ripgrep
      fd
      htop
      tree
      jq
      yq-go
      p7zip
    ];
    libs = [
      glibc
      openssl
      zlib
      libxml2
      libxslt
      sqlite
      readline
      ncurses
      cairo
      harfbuzz
      fribidi
      libpng
      libtiff
      libjpeg
      pango
      gdk-pixbuf
      blas
      lapack
      openblas
      libgcc
      libuv
    ];
  };
in
{
  base = base;
  buildInputs = builtins.concatLists (builtins.attrValues base);
  libraryPath = pkgs.lib.makeLibraryPath base.libs;
}
