home:
opts@{ ... }:
(with opts.pkgs; [
  R
  (with rPackages; [
    languageserver
    tidyverse
    data_table
    ggplot2
    shiny
    lintr
  ])
])
