{
  user,
  pkgs,
  lib,
  ...
}:
let
  asList = x: if !(builtins.isList x) then [ x ] else x;
  home = "/home/${user}";
  root = "${home}/.user";
  butlast = lst: lib.lists.take ((builtins.length lst) - 1) lst;
  last = lst: lib.lists.last lst;
  myEnv = rec {
    ADMIN = user;
    ADMIN_HOME = home;
    ADMIN_DIR = root;
    ADMIN_DIR_SH = "${root}/include";
    ADMIN_DIR_LIB = "${root}/lib";
    ADMIN_DIR_BIN = "${root}/bin";
    ADMIN_DIR_NIX = "${root}/nix";
    ADMIN_DIR_NIX_PKGS = "${root}/nix/pkgs";
    ADMIN_DIR_NIX_PROFILES = "${root}/nix/profiles";
    ADMIN_DIR_NIXOS = "${root}/nixos";
    ADMIN_DIR_NIXOS_PKGS = "${root}/nixos/pkgs";
    ADMIN_DIR_NVIM = "${root}/nvim";
    ADMIN_DIR_FOOT = "${root}/foot";
    ADMIN_DIR_SWAY = "${root}/sway";
    ADMIN_DIRS = builtins.concatStringsSep "\n" [
      "root=${ADMIN_DIR}"
      "home=${ADMIN_HOME}"
      "sh=${ADMIN_DIR_SH}"
      "lib=${ADMIN_DIR_LIB}"
      "bin=${ADMIN_DIR_BIN}"
      "nix=${ADMIN_DIR_NIX}"
      "nixos=${ADMIN_DIR_NIXOS}"
      "nix-pkgs=${ADMIN_DIR_NIX_PKGS}"
      "nix-profiles=${ADMIN_DIR_NIX_PROFILES}"
      "sway=${ADMIN_DIR_SWAY}"
      "foot=${ADMIN_DIR_FOOT}"
    ];
  };
in
rec {
  adminEnv = myEnv;
  homeMkPath =
    ps:
    let
      use = asList ps;
      fullpath = builtins.concatStringsSep "/" use;
    in
    "${adminEnv.ADMIN_HOME}/${fullpath}";
  adminMkPath =
    ps:
    let
      use = asList ps;
      fullpath = builtins.concatStringsSep "/" use;
    in
    "${adminEnv.ADMIN_DIR}/${fullpath}";
  adminPathExists = ps: builtins.pathExists (adminMkPath ps);
  homePathExists = ps: builtins.pathExists (homeMkPath ps);
  adminImport =
    ps: args:
    let
      use = asList ps;
      head = [ adminEnv.ADMIN_DIR_NIX ];
      middle = butlast use;
      lastPath = last use;
      fullPath = head ++ middle ++ [ (lastPath + ".nix") ];
    in
    import (builtins.concatStringsSep "/" fullPath) args;
  adminReadFile =
    ps:
    let
      use = asList ps;
      fullPath = [ adminEnv.ADMIN_DIR ] ++ use;
    in
    builtins.readFile (builtins.concatStringsSep "/" fullPath);
  adminInclude =
    ps:
    let
      use = asList ps;
      head = [ adminEnv.ADMIN_DIR_SH ];
      middle = butlast use;
      lastPath = last use;
      fullPath = head ++ middle ++ [ (lastPath + ".sh") ];
    in
    builtins.readFile (builtins.concatStringsSep "/" fullPath);
  adminMkShellHook =
    name:
    {
      init ? "",
      aliases ? "",
      utils ? "",
      postInit ? "",
      include ? [ ],
    }:
    let
      defaults = {
        init = adminInclude [ "init" ];
        aliases = adminInclude [ "aliases" ];
        utils = adminInclude [ "utils" ];
        postInit = adminInclude [ "postInit" ];
      };
      includeSh = map builtins.readFile include;
      includeShStr = builtins.concatStringsSep "\n" includeSh;
    in
    builtins.concatStringsSep "\n" [
      "${defaults.init}\n${init}"
      "${defaults.aliases}\n${aliases}"
      "${defaults.utils}\n${utils}"
      "${includeShStr}"
      "${defaults.postInit}\n${postInit}"
      "set-nix-PS1 ${name}"
    ];
  adminMkShellConfig =
    name:
    {
      env ? { },
      shellHook ? { },
      packages ? [ ],
    }:
    {
      env = env // adminEnv;
      shellHook = adminMkShellHook name shellHook;
      packages = packages;
    };
  adminMkShell =
    name:
    {
      env ? { },
      shellHook ? { },
      packages ? [ ],
    }:
    pkgs.mkShell (adminMkShellConfig name { inherit env shellHook packages; });
  nixosImport =
    ps: args:
    let
      use = asList ps;
      head = [ adminEnv.ADMIN_DIR_NIXOS ];
      middle = butlast use;
      lastPath = last use;
      fullPath = head ++ middle ++ [ (lastPath + ".nix") ];
    in
    import (builtins.concatStringsSep "/" fullPath) args;
  nixosImportPkg =
    ps:
    let
      use = asList ps;
      head = [
        adminEnv.ADMIN_DIR_NIXOS
        "pkgs"
      ];
      middle = butlast use;
      lastPath = last use;
      fullPath = head ++ middle ++ [ (lastPath + ".nix") ];
    in
    import (builtins.concatStringsSep "/" fullPath) { inherit user pkgs lib; };
  nixosImportPkgs = ps: map nixosImportPkg ps;
}
