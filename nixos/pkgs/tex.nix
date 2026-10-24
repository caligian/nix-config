{ pkgs, ... }:
[
  (pkgs.texlive.combine
  {
    inherit (pkgs.texlive)
      scheme-medium
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
      ;
  })
]
