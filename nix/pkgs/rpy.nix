{ pkgs, ... }:
let
  baseR = import <my/pkgs/r.nix> { inherit pkgs; };
  basePy = import <my/pkgs/python.nix> { inherit pkgs; };
in
baseR ++ basePy
