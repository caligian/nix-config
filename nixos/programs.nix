{
  user,
  lib,
  pkgs,
  ...
}:
let
  admin = import "/etc/nixos/admin.nix" { inherit user lib pkgs; };
  adminEnv = admin.adminEnv;
in
{
  programs = {
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      extraOptions = [
        "--config"
        "${adminEnv.ADMIN_DIR_SWAY}/config"
      ];
    };
    dconf.profiles.user.databases = [
      {
        settings."org/gnome/settings-daemon/plugins/power" = {
          sleep-inactive-ac-type = "nothing";
          sleep-inactive-battery-type = "nothing";
          sleep-inactive-ac-timeout = lib.gvariant.mkInt32 0;
          sleep-inactive-battery-timeout = lib.gvariant.mkInt32 0;
        };
      }
    ];
    ssh = {
      startAgent = false;
      # askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
    };
    steam.enable = true;
    adb.enable = true;
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
        xorg.libxcb
      ];
    };
    gamescope = {
      enable = false;
      capSysNice = true;
    };
    steam.gamescopeSession.enable = true;
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
