stty -ixon
unset TEMP TMP TEMPDIR TMPDIR
TMPDIR="$(mktemp -d /tmp/nix-shell-XXXXXX)"; export TMPDIR
gsettings set org.gnome.mutter.keybindings switch-monitor "[]" &>/dev/null

lua_utils_dir=~/Repos/lua-utils
nvim_utils_dir=~/Repos/nvim-utils
my_lua_utils_dir=~/.user/nvim/lib/lua-utils
my_nvim_utils_dir=~/.user/nvim/lib/nvim-utils

if [[ -d $lua_utils_dir ]] && [[ ! -d $my_lua_utils_dir ]]; then
  ln -sf $lua_utils_dir $my_lua_utils_dir
fi

if [[ -d $nvim_utils_dir ]] && [[ ! -d $my_nvim_utils_dir ]]; then
  ln -sf $nvim_utils_dir $my_nvim_utils_dir
fi
