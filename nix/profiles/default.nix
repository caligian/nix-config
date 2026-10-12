{
  pkgs ? import <nixpkgs> { },
}:

let
  home = builtins.getEnv "HOME";
  base = import <my/base.nix> "default" home { inherit pkgs; };
in
pkgs.mkShell base
