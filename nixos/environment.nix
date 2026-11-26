{
  user,
  lib,
  pkgs,
  config,
  ...
}:
let
  admin = import /etc/nixos/admin.nix {
    inherit
      user
      pkgs
      lib
      config
      ;
  };
  path = admin.path;
  myEnv = admin.env // {
    PERL5LIB = "${path.dir.lib}/perl";
    PYTHONPATH = "${path.dir.lib}/python/common_utils/src";
    PERLCRITICRC = path.file.perlcriticrc;
    PERLTIDY = path.file.perltidyrc;
    PYTHONIOENCODING = "utf-8";
    R_LINTR_LINTER_FILE = "${path.dir.root}/lintr";
    DXVK_CONFIG = "dxgi.maxFramerate=59; d3d9.maxFrameRate=59";
    R_LIBS_USER = "${path.dir.home}/R/library";
  };
  importPkgs =
    names:
    let
      allNames = if !builtins.isList names then [ names ] else names;
      baseDir = "/etc/nixos/pkgs";
      allPkgs = map (
        name:
        import "${baseDir}/${name}.nix" {
          inherit
            path
            user
            pkgs
            lib
            ;
        }
      ) allNames;
    in
    lib.flatten allPkgs;
  defaultPkgs = (
    importPkgs [
      "tex"
      "games"
      "cli"
      "tesseract"
      "vim"
      "neovim012"
      "ide"
      "clipboard"
      "sway"
      "screenshot"
      "lutris"
      "linux"
      "gui-apps"
      "perl"
      "python"
      "r"
      "nix"
      "themes"
      "qt"
      "gnome"
    ]
    ++ (with pkgs; [
      (writeScriptBin "init-R-project" ''
        #!/usr/bin/env Rscript

        args <- commandArgs(trailingOnly = TRUE)
        if (length(args) < 1) {
          stop("Usage: init-R-project <PROJECT>", call. = FALSE)
        }

        proj <- args[1]
        dirs <- c("R", "scripts", "bin", "data")

        for (.dir in dirs) {
          dir.create(
            file.path(proj, .dir), 
            recursive = TRUE,
            showWarnings = FALSE
          )
        }

        message(
          "Initialized R project at: ",
          normalizePath(proj, mustWork = FALSE)
        )
      '')
    ])
  );
in
{
  environment = {
    etc = {
      "xdg/autostart/vicinae.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Vicinae server
        Exec=vicinae server
        OnlyShowIn=GNOME;
        X-GNOME-Autostart-enabled=true
      '';
    };
    variables = {
      WLR_DRM_NO_DIRECT_SCANOUT = "1";
      GIT_SSL_CAINFO = "/etc/ssl/certs/ca-bundle.crt";
      CURL_CA_BUNDLE = "/etc/ssl/certs/ca-bundle.crt";
      OPENSSL_X509_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
      PATH = lib.mkAfter [
        "${path.dir.home}/bin"
        "${path.dir.root}/bin"
        "${path.dir.home}/.local/bin"
      ];
    }
    // myEnv;
    sessionVariables =
      myEnv
      // {
        GSK_RENDERER = "opengl";
        XDG_DATA_DIRS = lib.mkAfter [ "${pkgs.neovim-unwrapped}/share" ];
        QT_QPA_PLATFORM = "wayland";
        QT_QPA_PLATFORMTHEME = "qt5ct";
        EDITOR = "nvim";
        VISUAL = "gedit";
        BROWSER = "chromium";
        TERMINAL = "foot";
        NIXPKGS_ALLOW_UNFREE = "1";
      }
      // myEnv;
    systemPackages =
      defaultPkgs
      ++ (with pkgs; [
        cantarell-fonts # GNOME default font
        dejavu_fonts
        font-awesome
        inconsolata
        inconsolata-lgc
      ]);
  };
}
