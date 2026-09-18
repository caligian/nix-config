system-edit()
{
  local src="/etc/nixos/configuration.nix"
  local dst=~/configuration.nix

  sudo cp $src "${src}.bak"
  cp "$src" "$dst"
  chmod +rw "$dst"

  if nvim $dst; then
    sudo cp ~/configuration.nix /etc/nixos/configuration.nix
  else
    return 1
  fi
}

system() 
{
  case "$1" in
    edit)
      system-edit
       ;;
    reload)
      sudo nixos-rebuild switch
      ;;
    *)
      echo "Valid commands: edit, reload"
  esac
}

symlink()
{
  [[ -z $1 ]] && echo "No path provided" && return 1

  local src="$MY_DIR/$2"
  local dst="${3:-./}"

  if [[ ! -d $src ]]; then
    echo "Nonexistent path $src"
    return 1
  else
    ln -sf "$MY_DIR/$src" "$dst"
    if [[ $? -eq 0 ]]; then
      return 0
    else
      return 1
    fi
  fi
}

user-lock-exists()
{
  local file=$MY_DIR/lock/"$1"
  if [[ -f $file ]]; then
    return 0
  else
    return 1
  fi
}

user-lock()
{
  local filename="$1"
  [[ -z $filename ]] && echo "No filename provided" && return 1

  local dst=$MY_DIR/lock/"$filename"
  [[ ! -f $dst ]] && touch "$dst"
  return 0
}

user-edit()
{
  nvim -c ":Neotree bottom $MY_DIR/nix/"
}

user-reload-base()
{
  nix-shell ~/shell.nix
}

user-reload()
{
  if [[ -f ./shell.nix ]]; then
    nix-shell ./shell.nix
  else
    echo "No shell.nix exists in current directory"
    return 1
  fi
}

user-luajit-path() 
{
  lrocks --tree "$LUA_MODULES_DIR" path
}

user-luajit-init() 
{
  lrocks install --force lpath
  lrocks install --force luasystem
  lrocks install --force busted
  lrocks install --force ldoc
  lrocks install --force inspect
  lrocks install --force luautf8
  lrocks install --force luafilesystem
  lrocks install --force lua-cjson
  lrocks install --force luv
}

xdg-config-exists()
{
  local marker="$1"
  [[ -z $marker ]] && echo "No marker provided to append to ~/.config" && return 1
  [[ -f ~/.config/"$marker" ]]
}

xdg-config-exists-kitty()
{
  xdg-config-exists "kitty/kitty.conf"
}

xdg-config-exists-nvim()
{
  xdg-config-exists "nvim/init.lua"
}

xdg-config-exists-niri()
{
  xdg-config-exists "niri/config.kdl"
}

user-config-exists()
{
  local marker="$1"
  [[ -z $marker ]] && echo "No marker provided to append to $MY_DIR" && return 1
  [[ -f "$MY_DIR/$marker" ]]
}

user-config-exists-kitty()
{
  user-config-exists "kitty/kitty.conf"
}

user-config-exists-nvim()
{
  user-config-exists "nvim/init.lua"
}

user-config-exists-niri()
{
  user-config-exists "niri/config.kdl"
}

user-cp()
{
  [[ -z $1 ]] && echo "No path provided" && return 1
  local src="$MY_DIR/$1"
  local dst="${2:-./$1}"

  [[ ! -e $src ]] && echo "Invalid path $src" && return 1
  cp "$src" "$dst" && return 0 || return 1
}

user-ln()
{
  [[ -z $1 ]] && echo "No path provided" && return 1
  local src="$MY_DIR/$1"
  local dst="${2:-./$1}"

  [[ ! -e $src ]] && echo "Invalid path $src" && return 1
  ln -sf "$src" "$dst" && return 0 || return 1
}

user-symlink()
{
  user-ln "$@"
}

user-config-cp()
{
  user-cp "$1" ~/.config/"$2"
}

user-config-ln()
{
  user-ln "$1" ~/.config/"$2"
}

user-config-symlink()
{
  user-ln "$1" ~/.config/"$2"
}

user() 
{
  local action="$1"
  [[ -z $action ]] && echo "No action provided. Pass help to display help" && return 1
  shift 1

  case "$action" in
    edit)
      user-edit
      ;;
    reload-base)
      user-reload-base
      ;;
    reload)
      user-reload
      ;;
    symlink)
      symlink "$1" "$2"
      ;;
    lock)
      user-lock "$1"
      ;;
    lock-exists)
      user-lock-exists "$1"
      ;;
    init)
      user-luajit-init
      ;;
    help)
      echo "Commands:"
      printf "%s\n\t%s\n\n" "edit" "Edit files in $MY_DIR/nix" 
      printf "%s\n\t%s\n\n" "reload-base" "Run 'nix-shell ~/shell.nix'" 
      printf "%s\n\t%s\n\n" "reload" "Run 'nix-shell ./shell.nix'" 
      printf "%s\n\t%s\n\n" "lock {FILENAME}" "Make a lockfile in $MY_DIR/lock" 
      printf "%s\n\t%s\n\n" "lock-exists {NAME}" "Check if lockfile exists at $MY_DIR/lock" 
      printf "%s\n\t%s" "init" "Initialize base user nix shell" 
      return 0
      ;;
    *)
      echo "Unrecognized command $1. Pass help to display help"
      return 1
  esac
}

py() 
{
  /usr/bin/env python "$@"
}

ipy() 
{
  /usr/bin/env ipython "$@"
}

pip() 
{
  /usr/bin/env python -m pip "$@"
}

find-projects() 
{
  local root
  local depth

  if [[ -n "$1" && -n "$2" ]]; then
    root="$1"; depth="${2:-5}"; shift 2
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
  local projects=($(find "$root" -maxdepth $depth "$@" -type d -name '.PROJECT' -exec dirname {} + ))
  unset IFS

  for file in "${projects[@]}"; do
    echo $file 
  done
}

cd-project()
{
  local out="$(find-projects "$@" | fzf --prompt "cd project >")"
  if [[ -d "$out" ]]; then
    cd "$out"
    clear
    pwd
  fi
}

cd-project-in-home()
{
  local out="$(find-projects "$HOME" $1 | fzf --prompt "cd project >")"
  if [[ -d "$out" ]]; then
    cd "$out"
    clear
    pwd
  fi
}

user-git-clone()
{
  local repo="$1"
  [[ -z $repo ]] && echo "No repo URL provided" && return 1
  local dst="${2:-$MY_REPOS_DIR/$(basename $repo)}"
  shift 2
  git clone "$repo" "$dst" "$@"
}

git-ls()
{
  git ls-files
}

mapkeys()
{
  local lhs="$1"
  local func="$2"

  [[ -z $lhs ]] && echo "No keys provided" && return 1
  [[ -z $func ]] && echo "No function name provided" && return 1

  bind -x "\"$lhs\": $func"
}
