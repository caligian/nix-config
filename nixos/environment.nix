{
  user,
  lib,
  pkgs,
  ...
}:
let
  admin = import "/etc/nixos/admin.nix" { inherit user pkgs lib; };
  myEnv = admin.adminEnv // {
    PERL5LIB = "${myEnv.ADMIN_DIR_LIB}/perl";
    PYTHONPATH = "${myEnv.ADMIN_DIR_LIB}/python/common_utils/src";
    PERLCRITICRC = "${myEnv.ADMIN_DIR}/perlcriticrc";
    PERLTIDY = "${myEnv.ADMIN_DIR}/perltidyrc";
    PYTHONIOENCODING = "utf-8";
  };
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
  myPkgs = {
    tex = import "/etc/nixos/pkgs/tex.nix" { inherit pkgs; };
    r = import "/etc/nixos/pkgs/r.nix" { inherit pkgs; };
    python = import "/etc/nixos/pkgs/python.nix" { inherit pkgs; };
    perl = import "/etc/nixos/pkgs/perl.nix" { inherit pkgs; };
    lutris = import "/etc/nixos/pkgs/lutris.nix" { inherit pkgs; };
    vim = import "/etc/nixos/pkgs/vim.nix" { inherit pkgs; };
    neovim = import "/etc/nixos/pkgs/neovim012.nix" { inherit user lib pkgs; };
    tesseract = import "/etc/nixos/pkgs/tesseract.nix" { inherit pkgs; };
    dbus-sway-environment = [dbus-sway-environment];
  };
  allMyPkgs = (lib.flatten (builtins.attrValues myPkgs));
in
{
  environment = {
    variables = {
      GIT_SSL_CAINFO = "/etc/ssl/certs/ca-bundle.crt";
      CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
      OPENSSL_X509_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      PATH = lib.mkAfter [
        "${myEnv.ADMIN_HOME}/bin"
        "${myEnv.ADMIN_HOME}/.local/bin"
        myEnv.ADMIN_DIR_BIN
      ];
      ADMIN_DIRS = myEnv.ADMIN_DIRS;
    };
    sessionVariables = {
      XDG_DATA_DIRS = lib.mkAfter [ "${pkgs.neovim-unwrapped}/share" ];
      QT_QPA_PLATFORM = "wayland";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      EDITOR = "vi";
      VISUAL = "gedit";
      BROWSER = "chromium";
      TERMINAL = "foot";
      NIXPKGS_ALLOW_UNFREE = "1";
    }
    // removeAttrs myEnv [ "ADMIN_DIRS" ];
    systemPackages =
      (with pkgs; [
        # Audio stuff
        pavucontrol

        # Screenshot stuff
        grim
        slurp

        # Bluetooth packages
        blueman

        # nix utilities
        nix-init
        nix-prefetch-git
        nix-prefetch-github

        # waybar
        libsForQt5.qt5ct
        qt6Packages.qt6ct
        qt6.qtwayland
        qt5.qtwayland

        # xorg utilities
        xprop

        # minimal clipboard manager
        cliphist
        nwg-clipman

        # Fonts
        noto-fonts
        nerd-fonts.ubuntu-mono
        nerd-fonts.hack
        nerd-fonts.liberation

        # Gnome extras
        gnome-tweaks
        gnome-browser-connector
        nautilus

        # Terminal
        foot

        # Sway stuff
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
        # i3status-rust
        waybar

        # Network manager
        nmgui

        # GUI apps
        firefox
        chromium
        vlc
        eog
        foliate
        libreoffice-still
        gedit

        # Games
        gamescope
        vulkan-tools
        vulkan-loader
        amdctl
        xf86-video-amdgpu

        # IDE
        neovide
        tree-sitter
        unzip
        p7zip
        ctags
        universal-ctags
        nil
        texstudio
        geckodriver
        chromedriver
        selenium-manager
        selenium-server-standalone
        yank
        xclip
        wl-clipboard
        nixfmt
        bash-completion
        bash-git-prompt
        bash-snippets
        bash-language-server
        texlab

        # CLI
        git
        qpdf
        anydesk
        tmux
        brightnessctl
        nix-index
        zip
        aria2
        fzf
        fzy
        gnome-monitor-config
        cozette
        arashi
        guake
        xsel
        dmidecode
        sof-firmware
        alsa-utils
        zoom-us
        microcode-amd
        aerc
        msmtp
        unzip
        unrar
        cmus
        curl
        unzip
        ripgrep
        fd
        yazi
        chafa
        poppler-utils
        ffmpeg
        htop
        tree
        jq
        yq-go
        openssl
        zlib
        libxml2
        libxslt
        sqlite
        readline
        ncurses
        cairo
        harfbuzz
        fribidi
        libpng
        libtiff
        libjpeg
        pango
        gdk-pixbuf
        blas
        lapack
        openblas
        libuv
        mdf2iso
        wget
        dconf
        mpv
        parallel
        unoconv
        pandoc
        desktop-file-utils
        pipewire
        imagemagick
        mlocate
        wayland-utils
        qbittorrent
        exfat
        exfatprogs

        # Linux firmware
        linux
        linux-firmware

        # Android emulator
        #waydroid
        #waydroid-helper
        #waydroid-nftables

        # Lua stuff
        lua-language-server

        # themes
        stilo-themes
        adapta-gtk-theme
        marwaita
        canta-theme
        numix-icon-theme
        papirus-icon-theme
        yaru-theme
        mint-themes
        greybird

        # Nix
        nixd

        # Perl
        perlnavigator

        # Python
        python313
        ruff

        # Javascript/nodejs
        nodejs
      ])
      ++ allMyPkgs;
  };
}
