{
  pkgs ? import <nixpkgs> { },
  ...
}@args:

let
  home = builtins.getEnv "HOME";
  base = import <my/base.nix> "python" home { inherit pkgs; };
  pyPkgs = import <my/pkgs/python/base.nix> home { inherit pkgs;  };
in
pkgs.mkShell {
  env = base.env;
  shellHook = base.shellHook;
  packages = base.buildInputs ++ pyPkgs;
}
