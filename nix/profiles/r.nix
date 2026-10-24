{
  pkgs ? import <nixpkgs> { },
  ...
}:
let
  base = import <my/base.nix> "R" { inherit pkgs; };
  rPkgs = import <my/pkgs/r.nix> { inherit pkgs; };
in
pkgs.mkShell {
  env = base.env;
  shellHook = base.shellHook;
  packages = base.buildInputs ++ rPkgs;
}
