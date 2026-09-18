{
  pkgs ? import <nixpkgs> { },
  home ? builtins.getEnv "HOME",
}:
let
  myPkgs = import <my/pkgs.nix> { pkgs = pkgs; };
  utils = import <my/utils.nix> {
    inherit pkgs;
    inherit home;
  };
  user = utils.user;
  userDirs = user.dir;
  userHomeDirs = user.dir.home;
  systemPath = builtins.getEnv "PATH";
  libraryPath = myPkgs.libraryPath;
  myEnv = rec {
    # Directories
    MY_DIR = user.rootDir;
    MY_KITTY_DIR = userDirs.kitty;
    MY_NVIM_DIR = userDirs.nvim;
    MY_API_KEYS_DIR = userDirs.apiKeys;
    MY_LIB_DIR = userHomeDirs.lib.root;
    MY_PERL_LIB_DIR = "${userHomeDirs.lib.root}/perl";
    MY_PYTHON_LIB_DIR = "${userHomeDirs.lib.root}/python";
    MY_LUAJIT_LIB_DIR = "${userHomeDirs.lib.root}/luajit";
    MY_GAMES_DIR = userHomeDirs.games;
    MY_REPOS_DIR = userHomeDirs.repos;
    MY_MUSIC_DIR = userHomeDirs.music;
    MY_DOWNLOADS_DIR = userHomeDirs.downloads;
    MY_PROJECTS_DIR = userHomeDirs.projects;
    MY_WORK_DIR = userHomeDirs.work;
    MY_SCRIPTS_DIR = userHomeDirs.scripts;

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
    PERL5LIB = "${MY_PERL_LIB_DIR}";
    LUA_MODULES_DIR = "${MY_LUAJIT_LIB_DIR}";
    PIP_TARGET = "${MY_PYTHON_LIB_DIR}";

    # Temporary overriding until I publish the package
    PYTHONPATH = "$PYTHONPATH:${MY_REPOS_DIR}/common_utils/src";
    PYTHONIOENCODING = "utf-8";

    # PATH
    PATH = "${home}/bin:${home}/.local/bin:${systemPath}";

    # Library path
    LD_LIBRARY_PATH = "${libraryPath}";

    # perl stuff
    PERLCRITICRC = "${home}/.perlcriticrc";
  };
in
myEnv
