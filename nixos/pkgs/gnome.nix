{ pkgs, ... }:
(with pkgs; [
  gnome-tweaks
  gnome-monitor-config
])
++ (with pkgs.gnomeExtensions; [
  appindicator
  caffeine
  shortcuts
  no-overview
  vertical-workspaces
  just-perfection
  blur-my-shell
  focus-on-active-window
])
