{
  pkgs ? import <nixpkgs> { },
}:
let
  build = import <my/pkgs/build.nix> { inherit pkgs; };
in
build
