{ pkgs, ... }:
(with pkgs; [
  libsForQt5.qt5ct
  qt6Packages.qt6ct
  qt6.qtwayland
  qt5.qtwayland
])
