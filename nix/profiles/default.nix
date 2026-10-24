{
  pkgs ? import <nixpkgs> { },
}:

let
  base = import <my/base.nix> "default" { inherit pkgs; };
in
pkgs.mkShell base
