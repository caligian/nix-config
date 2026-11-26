{ pkgs, ... }:
(pkgs.texliveMedium.withPackages (
  ps: with ps; [
    standalone
    preview
    apacite
    latexmk
    biber
    xetex
    fontawesome
    xurl
    booktabs
    graphics
    enumitem
    xcolor
    noto
    paracol
    chemfig
    footmisc
    titlesec
  ]
))
