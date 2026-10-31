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
    ]
  );
in
{
  environment = {
    variables = {
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
