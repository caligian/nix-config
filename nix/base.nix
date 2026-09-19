name: home: pkgs:
let
  utils = import <my/utils.nix> { inherit home pkgs; };
  env = import <my/env.nix> { inherit home; };
  buildInputs = import <my/pkgs/base.nix> home { inherit pkgs env; };
  readShellFile = utils.user.readShellFile;
  shellFile = {
    init = readShellFile "init";
    utils = readShellFile "utils";
    postInit = readShellFile "post-init";
  };
  shellHook = ''
    ${shellFile.init}
    ${shellFile.utils}

    function lrocks() {
      luarocks --local --tree "$LUA_MODULES_DIR" --lua-version 5.1 "$@" RT_DIR="${pkgs.glibc}"
    }

    function luajit-install() {
      lrocks install --force "$@" RT_DIR="${pkgs.glibc}"
    }

    ${shellFile.postInit}
    set-nix-PS1 "${name}"
  '';
in
{
  inherit env buildInputs shellHook;
}
