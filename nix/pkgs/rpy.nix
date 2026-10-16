home:
{ pkgs, ... }:
let
  baseR = import <my/pkgs/r.nix> home { inherit pkgs; };
  basePy = import <my/pkgs/python.nix> home { inherit pkgs; };
in
baseR ++ basePy
