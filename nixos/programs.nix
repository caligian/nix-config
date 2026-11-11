{
  user,
  lib,
  pkgs,
  config,
  ...
}:
let
  isFile = builtins.pathExists;
  admin = import "/etc/nixos/admin.nix" {
    inherit
      user
      lib
      pkgs
      config
      ;
  };
  path = admin.path;
  swayDir = path.dir.sway;
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
      name = "Terminal (foot)";
      run = "foot";
      keys = "<Super>Return";
    }
    {
      name = "Neovim GUI";
      run = "neovide";
      keys = "<Super><Shift>Return";
    }
    {
      name = "Libreoffice";
      run = "libreoffice";
      keys = "<Super><Alt>l";
    }
  ];
in
{
  programs = {
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraOptions = [
        "--config"
        "${swayDir}/config"
      ];
    };
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
    ssh = {
      startAgent = false;
      # askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    };
    steam.enable = false;
    gpaste.enable = true;
    firefox.enable = true;
    chromium.enable = true;
    appimage.enable = true;
    nm-applet.enable = true;
    direnv = {
      enable = false;
      nix-direnv.enable = true;
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        libxcb
        zlib
        stdenv.cc.cc
        zstd
        glib
        glibc
        libgcc
        util-linux
        openssl
        curl
        libssh
        libxml2
        expat
        gtk3
        gtk4
        cairo
        pango
        atk
        gdk-pixbuf
        libGL
        libva
        vulkan-loader
        libgbm
        libdrm
        wayland
        pipewire
        alsa-lib
        libpulseaudio
        fontconfig
        freetype
        icu
        coreutils
        pciutils
        sysfsutils
        libX11
        libXcomposite
        libXdamage
        libXext
        libXfixes
        libXrandr
        libXrender
        libXtst
        libXi
        libxshmfence
        libxkbcommon
        pipewire
        alsa-lib
        libpulseaudio
      ];
    };
    gamescope = {
      enable = false;
      capSysNice = true;
    };
    steam = {
      gamescopeSession.enable = true;
    };
    tmux = {
      enable = true;
      baseIndex = 1;
      newSession = true;
      escapeTime = 0;
      secureSocket = false;
      clock24 = true;
      historyLimit = 50000;
      plugins = with pkgs; [
        tmuxPlugins.yank
        tmuxPlugins.better-mouse-mode
        tmuxPlugins.jump
        tmuxPlugins.lazy-restore
      ];
      extraConfig = ''
        unbind C-b
        set -g prefix M-space
        bind M-space send-prefix

        set -g default-terminal "screen-256color"
        set -g default-command "/usr/bin/env bash"
        set -g mouse
        set -ga terminal-overrides ",xterm-256color:Tc"

        bind r source-file ~/.user/tmux.conf
        bind h select-pane -L
        bind l select-pane -R
        bind k select-pane -U
        bind j select-pane -D

        bind -n C-Left resize-pane -L 5
        bind -n C-Right resize-pane -R 5
        bind -n C-Up resize-pane -U 5
        bind -n C-Down resize-pane -D 5

        bind -n S-Left resize-pane -L 2
        bind -n S-Right resize-pane -R 2
        bind -n S-Up resize-pane -U 1
        bind -n S-Down resize-pane -D 1
      '';
    };
  };
}
