{ path, pkgs, ... }:
let
  dbus-sway-environment = pkgs.writeTextFile {
    name = "dbus-sway-environment";
    destination = "/bin/dbus-sway-environment";
    executable = true;
    text = ''
      dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
      systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
      systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
    '';
  };
  waybarConfigDir = path.dir.waybar;
  waybarStyleCss = "${waybarConfigDir}/style.css";
  waybarConfig = "${waybarConfigDir}/config.jsonc";
  sway-waybar = pkgs.writeTextFile {
    name = "sway-waybar";
    destination = "/bin/sway-waybar";
    executable = true;
    text = ''
      waybar -s "${waybarStyleCss}" -c "${waybarConfig}"
    '';
  };
in
(with pkgs; [
  wofi
  rofi
  swayosd
  networkmanagerapplet
  upower
  dbus
  mako
  fuzzel
  swaybg
  swaylock
  waybar
])
++ [
  dbus-sway-environment
  sway-waybar
]
