{
  pkgs,
  ...
}:
let
  tesseract = pkgs.tesseract.override {
    enableLanguages = [
      "eng"
      "mar"
      "hin"
      "osd"
    ];
  };
  ocrmypdf = pkgs.ocrmypdf.override { tesseract = tesseract; };
  vim = (import "/etc/nixos/vim.nix" { inherit pkgs; });
  myPkgs = [
    tesseract
    ocrmypdf
    vim
  ];
in
{
  environment.systemPackages =
    (with pkgs; [
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
      xorg.xprop

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
      gnome-terminal
      nautilus

      # Terminal
      foot

      # Sway stuff
      wofi
      rofi
      swayosd
      networkmanagerapplet
      pavucontrol
      upower
      dbus
      mako
      fuzzel
      swaybg
      swaylock
      i3status-rust

      (pkgs.writeTextFile {
        name = "dbus-sway-environment";
        destination = "/bin/dbus-sway-environment";
        executable = true;
        text = ''
          dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=sway
          systemctl --user stop pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
          systemctl --user start pipewire pipewire-media-session xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-gtk
        '';
      })

      # Network manager
      nmgui

      # GUI apps
      firefox
      chromium
      vlc
      eog
      foliate
      rstudio
      libreoffice-still
      gedit

      # Games
      gamescope
      vulkan-tools
      vulkan-loader
      amdctl
      xf86-video-amdgpu

      (lutris.override {
        extraLibraries = pkgs: with pkgs; [ libgudev ];
        extraPkgs =
          pkgs: with pkgs; [
            gst_all_1.gst-plugins-base
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
            gst_all_1.gst-libav
            libtheora
            libxml2
            openssl_1_1
            libwebp
            libvdpau
            speex
            libdrm
          ];
      })

      # IDE
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
      xsel
      wl-clipboard
      nixfmt-rfc-style
      bash-completion
      bash-git-prompt
      bash-snippets
      bash-language-server
      texlab

      # CLI
      poppler-utils
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
      pavucontrol
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
      git
      curl
      wget
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
      git
      curl
      dconf
      cmus
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
      linux_latest
      linux-firmware

      #waydroid
      #waydroid-helper
      #waydroid-nftables

      luajit
      luajitPackages.inspect

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

      # Lua
      lua-language-server

      # Nix
      nixd

      # Perl
      perlnavigator
      (perl.withPackages (
        ps: with ps; [
          Moose
          MooseXGetopt
          MooseXTypes
          MooseXTypesPathTiny
          NamespaceAutoclean
          CarpAssert
          PathTiny
          FileTouch
          FileUtil
          FileSlurp
          JSONXS
          ConfigAny
          ConfigTiny
          YAMLLibYAML
          PLS
          ArchiveTar
          GetoptLongDescriptive
        ]
      ))

      # Python
      ruff
      python313

      # Javascript/nodejs
      nodejs

      # Latex
      (texlive.combine {
        inherit (texlive)
          scheme-medium
          apacite
          latexmk
          biber
          xetex
          fontawesome
          xurl
          booktabs
          graphics
          enumitem
          xcolor
          noto
          paracol
          chemfig
          footmisc
          titlesec
          ;
      })
    ])
    ++ myPkgs;
}
