{ pkgs, ... }:
(with pkgs; [
  winetricks
  dxvk
  cabextract
  p7zip
  vkd3d-proton
  gamescope
  linuxPackages_zen.cpupower

  (with wineWow64Packages; [
    fonts
    stagingFull
  ])
])
