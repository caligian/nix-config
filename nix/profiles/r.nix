{
  pkgs ? import <nixpkgs> { },
  ...
}@args:
let
  home = builtins.getEnv "HOME";
  base = import <my/base.nix> "R" home { inherit pkgs; };
  rPkgs = import <my/pkgs/r.nix> home { inherit pkgs;  };
in
pkgs.mkShell {
  env = base.env;
  shellHook = base.shellHook;
  packages = base.buildInputs ++ rPkgs;
}
