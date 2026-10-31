{
  user,
  pkgs,
  lib,
  config,
  ...
}:
let
  home = "/home/${user}";
  root = "${home}/.user";
  myEnv = {
    ADMIN = user;
    ADMIN_HOME = home;
    ADMIN_DIR = root;
    ADMIN_LIB_DIR = "${root}/lib";
    ADMIN_BIN_DIR = "${root}/bin";
    ADMIN_SWAY_DIR = "${root}/sway";
    ADMIN_WAYBAR_DIR = "${root}/sway/waybar";
    ADMIN_NVIM_DIR = "${root}/nvim";
    ADMIN_FOOT_DIR = "${root}/foot";
    ADMIN_PKGS_DIR = "${root}/nixos/pkgs";
    ADMIN_NIXOS_DIR = "${root}/nixos";
    ADMIN_NIX_DIR = "${root}/nix";
  };
in
rec {
  user = user;
  rootDir = root;
  env = myEnv;
  path = {
    dir = rec {
      nix = myEnv.ADMIN_NIX_DIR;
      pkgs = myEnv.ADMIN_PKGS_DIR;
      root = myEnv.ADMIN_DIR;
      home = myEnv.ADMIN_HOME;
      lib = "${root}/lib";
      bin = "${root}/bin";
      nixos = "${root}/nixos";
      nvim = "${root}/nvim";
      nixosPkgs = "${root}/nixos/pkgs";
      include = "${root}/include";
      sway = env.ADMIN_SWAY_DIR;
      foot = env.ADMIN_FOOT_DIR;
      waybar = env.ADMIN_WAYBAR_DIR;
    };
    file = {
      perltidyrc = "${path.dir.root}/perltidyrc";
      perlcriticrc = "${path.dir.root}/perlcriticrc";
      bashrc = "${path.dir.root}/bashrc";
    };
  };
  importPkg =
    name:
    import "${path.dir.nixosPkgs}" {
      adminDir = path.dir.config;
      inherit
        user
        pkgs
        lib
        config
        path
        ;
    };
  sourceSh = name: builtins.readFile "${path.dir.include}/${name}.nix";
  shellHook = {
    default = ''
      ${sourceSh "init"}
      ${sourceSh "aliases"}
      ${sourceSh "utils"}
      ${sourceSh "post-init"}
    '';
    new =
      {
        init ? "",
        aliases ? "",
        utils ? "",
        postInit ? "",
      }:
      ''
        ${sourceSh "init"}
        ${init}

        ${sourceSh "aliases"}
        ${aliases}

        ${sourceSh "utils"}
        ${utils}

        ${sourceSh "post-init"}
        ${postInit}
      '';
  };
}
