{ pkgs, ... }:
[
  (pkgs.rWrapper.override
  {
    packages = with pkgs.rPackages; [
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
    ];
  })
]
