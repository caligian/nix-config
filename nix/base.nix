name: home:
{
  pkgs ? import <nixpkgs> { },
  env ? { },
  buildInputs ? [ ],
  shellHook ? "",
}:
let
  utils = import <my/utils.nix> home { inherit pkgs; };
  myEnv = (import <my/env.nix> home { inherit pkgs; }) // env;
  myBuildInputs = import <my/pkgs/base.nix> home {
    inherit pkgs;
    env = myEnv;
  } ++ [pkgs.neovide];
  source = utils.user.source;
  initSh = source "init.sh";
  utilsSh = source "utils.sh";
  postInitSh = source "post-init.sh";
  myShellHook = ''
    set-nix-PS1 "${name}"
    ${initSh}
    ${utilsSh}
    ${postInitSh}
    ${shellHook}
  '';
in
{
  env = myEnv // env;
  shellHook = myShellHook;
  buildInputs = myBuildInputs ++ buildInputs;
}
