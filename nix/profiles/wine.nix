{
  pkgs ? import <nixpkgs> { },
}:

let
  myEnv = import <my/env.nix> { inherit pkgs; };
in
pkgs.mkShell {
  name = "wine";
  buildInputs = with pkgs; [
    winetricks
    p7zip
    cabextract
    python313
    gamescope
    wineWow64Packages.stable

    (with python313Packages; [
      iniparse
      termcolor
    ])
  ];
  env = myEnv;
  shellHook = ''
    echo "Base games environment setup successfully"
    set-nix-PS1 games

    with-wineprefix()
    {
      local prefix="''${1:-~/Games/default-prefix}"
      [[ -z $1 ]] && echo "No prefix provided" && return 1
      [[ ! -d $1 ]] && printf "Invalid directory %s" "$1" && return 1

      prefix="$(realpath $1)"
      shift 1
      WINEPREFIX="$prefix" "$@"
    }
  '';
}
