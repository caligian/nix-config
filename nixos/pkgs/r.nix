{ pkgs, ... }:
let
  rPkgs = with pkgs.rPackages; [
    stringdist
    rstudiothemes
    languageserver
    tidyverse
    data_table
    ggplot2
    shiny
    lintr
    tidyr
    RSQLite
    readr
    dbplyr
    argparse
    writexl
    bslib
    rmarkdown
    knitr
    devtools
    testthat
    here
    janitor
    fs
    usethis
    roxygen2
    pkgbuild
    tinytex
    reticulate
    targets
    readxl
  ];
  r = (
    pkgs.rWrapper.override {
      packages = rPkgs;
    }
  );
  rStudio = (
    pkgs.rstudioWrapper.override {
      packages = rPkgs;
    }
  );
in
[
  r
  rStudio
]
