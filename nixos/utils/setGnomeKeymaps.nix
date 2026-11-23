{
  lib,
  pkgs,
  ...
}:
let
  adminDir = {
    bin = "/etc/nixos/bin";
    foot = "/etc/nixos/foot";
    sway = "/etc/nixos/sway";
  };
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
      run = "foot -c ${adminDir.foot}/config.ini";
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
      run = "${adminDir.bin}/scroll-lock-led";
      name = "turn on keyboard LED by scroll-lock";
    }
  ];
  mapper =
    dconfSettings: maps:
    let
      withDefaults = myGnomeKeymaps ++ maps;
      withMaps = dconfSettings // withDefaults;
    in
    withMaps;
in
mapper
