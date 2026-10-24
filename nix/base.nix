name:
{
  pkgs ? import <nixpkgs> { },
  env ? { },
  buildInputs ? [ ],
  shellHook ? "",
}:
let
  myEnv = (import <my/env.nix> { inherit pkgs; }) // env;
  myBuildInputs = import <my/pkgs/build.nix> { inherit pkgs; };
  includeDir = (builtins.getEnv "ADMIN_DIR") + "/include";
  source = name: builtins.readFile (includeDir + "/" + name + ".sh");
  initSh = source "init";
  utilsSh = source "utils";
  postInitSh = source "post-init";
  myShellHook = ''
    set-nix-PS1 "${name}"
    ${initSh}
    ${utilsSh}
    ${postInitSh}
    ${shellHook}
  '';
in
{
  env = myEnv;
  shellHook = myShellHook;
  buildInputs = myBuildInputs ++ buildInputs;
}
