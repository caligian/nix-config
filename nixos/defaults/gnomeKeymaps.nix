{
  lib,
  pkgs,
  ...
}@args:
import "/etc/nixos/utils/setGnomeKeymaps.nix" ({ inherit lib pkgs; } // args) [
  {
    keys = "<Super>slash";
    run = "guake";
    name = "guake";
  }
  {
    keys = "<Super>Return";
    run = "foot -c /home/Kerambit/.user/foot/config.ini";
    name = "terminal";
  }
  {
    keys = "<Super>b";
    run = "firefox --new-window";
    name = "firefox";
  }
  {
    keys = "<Control><Super>Return";
    run = "nautilus";
    name = "File manager";
  }
  {
    keys = "<Super>c";
    run = "chromium";
    name = "chromium";
  }
  {
    keys = "<Control><Super>l";
    run = "libreoffice";
    name = "libreoffice";
  }
  {
    keys = "<Shift><Super>Return";
    run = "neovide";
    name = "neovide";
  }
  {
    keys = "<Super>space";
    run = "vicinae toggle";
    name = "launcher";
  }
  {
    keys = "Pause";
    run = "/home/Kerambit/.user/bin/scroll-lock-led";
    name = "turn on keyboard LED by scroll-lock";
  }
]
