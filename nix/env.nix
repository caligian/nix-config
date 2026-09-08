{
  pkgs ? import <nixpkgs> {},
  home ? builtins.getEnv "HOME",
}:
let
  utils = import <my/utils.nix> { pkgs = pkgs; home = home; };
  myPkgs = import <my/pkgs.nix> { pkgs = pkgs; };
  buildInputs = myPkgs.buildInputs;
  user = utils.user;
  userDir = user.dir;
  systemPath = builtins.getEnv "PATH";
  libraryPath = myPkgs.libraryPath;
  myEnv = rec {
    # Directories
    MY_DIR = userDir;
    MY_PKGS_DIR = "${home}/pkgs";
    MY_GAMES_DIR = "${home}/Games";
    MY_REPOS_DIR = "${home}/Repos";
    MY_MUSIC_DIR = "${home}/Music";
    MY_DOWNLOADS_DIR = "${home}/Downloads";
    MY_PROJECTS_DIR = "${home}/Projects";
    MY_WORK_DIR = "${home}/Work";
    MY_SCRIPTS_DIR = "${home}/Scripts";
    MY_API_KEYS_DIR = "${userDir}/api-keys";

    # API keys
    DEEPSEEK_API_KEY_FILE = "${MY_API_KEYS_DIR}/deepseek.txt";
    DEEPSEEK_API_KEY = "";

    # Editors and tools
    EDITOR = "nvim";
    VISUAL = "gedit";
    BROWSER = "chromium";
    TERMINAL = "kitty";
    TERM = "xterm-256color";

    # Nix settings
    NIXPKGS_ALLOW_UNFREE = "1";

    # Language paths
    PERL5LIB = "${MY_PKGS_DIR}/perl";
    LUA_MODULES_DIR = "${MY_PKGS_DIR}/lua";
    PIP_TARGET = "${MY_PKGS_DIR}/python";

    # Temporary overriding until I publish the package
    PYTHONPATH = "${PIP_TARGET}:${MY_REPOS_DIR}/common_utils/src";
    PYTHONIOENCODING = "utf-8";

    # PATH
    PATH = "${home}/bin:${home}/.local/bin:${systemPath}";

    # Library path
    LD_LIBRARY_PATH = "${libraryPath}";

    # perl stuff
    PERLCRITICRC = "${home}/.perlcriticrc";

    # Misc
    IN_NIX_SHELL = "1";
  };
in
  myEnv
