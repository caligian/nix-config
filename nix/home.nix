{
  home,
  pkgs ? import <nixpkgs> { },
}:
let
  scriptsDir = home + "/.user/scripts";
  homeSetupSh = builtins.readFile "${scriptsDir}/setup-home.sh";
  nixDir = home + "/.user/nix";
  envDir = home + "/.user/env";
  lockDir = home + "/.user/lock";
  myEnv = import (nixDir + "/env.nix") {
    pkgs = pkgs;
    home = home;
  };
  myPkgs = import (nixDir + "/pkgs.nix") { pkgs = pkgs; };
  neovim = import (nixDir + "/nvim.nix") {
    pkgs = pkgs;
    home = home;
  };
  buildInputs = myPkgs.buildInputs ++ [ neovim ];
  luarocksLock = lockDir + "/luarocks";
  shellHook = ''
    ${homeSetupSh}

    if [[ ! -f ${luarocksLock} ]]; then
      lrocks-setup
      touch ${luarocksLock}
    fi

    set IFS=$'\n'
    envFiles=($(ls ${envDir}/*.sh))
    unset IFS

    for file in ''${envFiles[@]}; do
      eval "$(cat $file)" 
    done

    envFiles=""
    bind -x '"\C-@": "project-cd"'
  '';
in
{
  env = myEnv;
  shellHook = shellHook;
  buildInputs = buildInputs;
}
