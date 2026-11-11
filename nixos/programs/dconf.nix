{
  lib,
  pkgs,
  ...
}:
let
  setGnomeKeymaps =
    specs:
    let
      isScriptPath =
        p:
        let
          s = toString p;
        in
        lib.hasPrefix "/" s && builtins.pathExists s;
      mkPath = i: "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}/";

      mkEntry =
        i: spec:
        let
          cmd =
            if isScriptPath spec.run then
              toString (pkgs.writeShellScript "gnome-kb-${toString i}" (builtins.readFile spec.run))
            else
              spec.run;
        in
        {
          name = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}";
          value = {
            inherit (spec) name;
            binding = spec.keys;
            command = cmd;
          };
        };
    in
    builtins.listToAttrs (lib.imap0 mkEntry specs)
    // {
      "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = builtins.genList mkPath (
        builtins.length specs
      );
    };
  myGnomeKeymaps = setGnomeKeymaps [
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
      keys = "Pause";
      run = "/home/Kerambit/.user/bin/scroll-lock-led";
      name = "turn on keyboard LED by scroll-lock";
    }
  ];
in
{
  dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "nothing";
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
          sleep-inactive-battery-timeout = lib.gvariant.mkInt32 0;
        };
        "org/gnome/shell" = {
          overview-on-all-monitors = true;
          dynamic-workspaces = false;
        };
        "org/gnome/mutter" = {
          workspaces-only-on-primary = false;
        };
        "org/gnome/desktop/wm/preferences" = {
          num-workspaces = lib.gvariant.mkInt32 10;
        };
      }
      // myGnomeKeymaps;
    }
  ];
}
