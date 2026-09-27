home:
{
  pkgs ? import <nixpkgs> { },
}:
let
  utils = import <my/utils.nix> home { inherit pkgs; };
  user = utils.user;
  userDirs = user.dir;
  userHomeDirs = user.dir.home;
  systemPath = builtins.getEnv "PATH";
  myEnv = rec {
    # Directories
    MY_DIR = user.rootDir;
    MY_KITTY_DIR = userDirs.kitty;
    MY_NVIM_DIR = userDirs.nvim;
    MY_API_KEYS_DIR = userDirs.apiKeys;
    MY_INCLUDE_DIR = userDirs.include;
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
    DEEPSEEK_API_KEY_FILE = "${MY_API_KEYS_DIR}/deepseek.txt";
    SARVAMAI_API_KEY_FILE = "${home}/sarvamai-api-key.txt";
    EDITOR = "nvim";
    VISUAL = "gedit";
    BROWSER = "chromium";
    TERMINAL = "kitty";
    TERM = "xterm-256color";
    NIXPKGS_ALLOW_UNFREE = "1";
    PERL5LIB = "${MY_PERL_LIB_DIR}";
    LUA_MODULES_DIR = "${MY_LUAJIT_LIB_DIR}";
    PYTHONPATH = "$PYTHONPATH:${MY_REPOS_DIR}/common_utils/src";
    PYTHONIOENCODING = "utf-8";
    PATH = "${home}/bin:${home}/.local/bin:${systemPath}";
    PERLCRITICRC = "${home}/.perlcriticrc";
  };
in
myEnv
