{ pkgs, ... }:
(with pkgs; [
  gnome-tweaks
  gnome-monitor-config
])
++ (with pkgs.gnomeExtensions; [
  appindicator
  caffeine
  blur-my-shell
  shortcuts
  impatience
  no-overview
  tiling-assistant
  vertical-workspaces
  compiz-alike-magic-lamp-effect
])
