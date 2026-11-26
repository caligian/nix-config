{
  user,
  pkgs,
  lib,
  config,
  ...
}:
let
  adminUser = user;
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
    ADMIN_NIXOS_DIR = "${root}/nixos";
    ADMIN_NIXOS_UTILS_DIR = "${root}/nixos/utils";
    ADMIN_NIXOS_PKGS_DIR = "${root}/nixos/pkgs";
    ADMIN_INCLUDE_DIR = "${root}/include";
    ADMIN_PERLTIDYRC = "${root}/perltidyrc";
    ADMIN_PERLCRITICRC = "${root}/perlcriticrc";
    ADMIN_BASHRC = "${root}/bashrc";
  };
in
rec {
  user = adminUser;
  rootDir = root;
  env = myEnv;
  path = {
    dir = {
      root = myEnv.ADMIN_DIR;
      pkgs = myEnv.ADMIN_PKGS_DIR;
      home = myEnv.ADMIN_HOME;
      lib = myEnv.ADMIN_LIB_DIR;
      bin = myEnv.ADMIN_BIN_DIR;
      nvim = myEnv.ADMIN_NVIM_DIR;
      include = myEnv.ADMIN_INCLUDE_DIR;
      sway = env.ADMIN_SWAY_DIR;
      foot = env.ADMIN_FOOT_DIR;
      waybar = env.ADMIN_WAYBAR_DIR;
      nixos = myEnv.ADMIN_NIXOS_DIR;
      nixosPkgs = myEnv.ADMIN_NIXOS_PKGS_DIR;
      nixosUtils = myEnv.ADMIN_NIXOS_UTILS_DIR;
    };
    file = {
      bashrc = myEnv.ADMIN_BASHRC;
      perltidyrc = myEnv.ADMIN_PERLTIDYRC;
      perlcriticrc = myEnv.ADMIN_PERLCRITICRC;
    };
  };
  dir = path.dir;
  file = path.file;
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
