stty -ixon
unset TEMP TMP TEMPDIR TMPDIR
TMPDIR="$(mktemp -d /tmp/nix-shell-XXXXXX)"; export TMPDIR
gsettings set org.gnome.mutter.keybindings switch-monitor "[]" &>/dev/null

alias nvim-config="nvim $HOME/.config/nvim"
alias kitty-config="nvim $HOME/.config/kitty/kitty.conf"
alias symlink="ln -sf"
alias ls="ls --color=auto -ctrpA"
alias nixos-edit="nvim -c 'SudaRead /etc/nixos/configuration.nix'"
alias nixos-reload="sudo nixos-rebuild switch"

function lrocks() {
  luarocks --local --tree "$LUA_MODULES_DIR" --lua-version 5.1 "$@" RT_DIR="${pkgs.glibc}"
}

function lrocks-install() {
  lrocks install --force "$@" RT_DIR="${pkgs.glibc}"
}

function lrocks-path() {
  lrocks --tree "$LUA_MODULES_DIR" path
}

function lrocks-setup() {
  lrocks-install lpath
  lrocks-install luasystem
  lrocks-install busted
  lrocks-install ldoc
  lrocks-install inspect
  lrocks-install luautf8
  lrocks-install luafilesystem
  lrocks-install lua-cjson
}

function python() {
  if [[ -f ./bin/python ]]; then
    ./bin/python "$@"
  else
    /usr/bin/env python "$@"
  fi
}

function ipython() {
  if [[ -f ./bin/python ]]; then
    ./bin/ipython "$@"
  else
    /usr/bin/env ipython "$@"
  fi
}

function pip() {
  if [[ -f ./bin/python ]]; then
    ./bin/python -m pip "$@"
  else
    /usr/bin/env python -m pip "$@"
  fi
}

function project-find() {
  local root
  local depth

  if [[ -n "$1" && -n "$2" ]]; then
    root="$1"; depth="$2"; shift 2
  elif [[ -n "$1" ]]; then
    root="$1"; depth=5; shift 1
  else
    root="./"; depth=5
  fi

  if [[ ! -d "$root" ]]; then
    echo "Nonexistent directory $root" && return 1
  fi

  root="$(realpath "$root")"
  IFS=$'\n'
  local projects=($(find "$root" -maxdepth $depth "$@" -type d -name '.git' -exec dirname {} + ))
  unset IFS

  for file in "${projects[@]}"; do
    echo $file 
  done
}

function project-cd(){
  local out="$(project-find "$@" | fzf --prompt "cd project >")"
  if [[ -d "$out" ]]; then
    cd "$out"
    pwd
  fi
}

function template-copy() {
  local src="$HOME/.user/templates/$1"
  local dst="${2:-$1}"

  if [[ -z $src ]]; then
    echo 'No template filename provided'
  elif [[ ! -f $src ]]; then 
    echo "Nonexistent template: $src"
    return 1
  fi

  if cp -v "$src" "$dst"; then
    return 0
  else
    return 1
  fi
}

if [[ -d $HOME/Repos ]]; then
  if [[ -d $HOME/Repos/lua-utils ]] && [[ ! -L $HOME/.user/nvim/lua-utils ]]; then
    ln -sf $HOME/Repos/lua-utils/lua-utils $HOME/.user/nvim/lua-utils
  fi
  if [[ -d $HOME/Repos/nvim-utils ]] && [[ ! -L $HOME/.user/nvim/nvim-utils ]]; then
    ln -sf $HOME/Repos/nvim-utils/nvim-utils $HOME/.user/nvim/nvim-utils
  fi
fi

