{
  # pkgs ? import <nixpkgs> { },
  ...
}:
let
  home = builtins.getEnv "ADMIN_HOME";
  myEnv = {
    # Directories
    DEEPSEEK_API_KEY_FILE = "${home}/deepseek.txt";
    SARVAMAI_API_KEY_FILE = "${home}/sarvamai-api-key.txt";
  };
in
myEnv
