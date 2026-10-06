symlink()
{
  [[ -z $1 ]] && echo "No path provided" && return 1
  [[ -z $2 ]] && echo "No link name provided" && return 1
  ln -sf "$1" "$2"
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
  local dir="${1:-./}"
  local depth="${2:-5}"

  [[ -z $dir ]] && echo "No directory provided" && return 1
  [[ ! -d $dir ]] && echo "Nonexistent directory provided $dir" && return 1 

  fd -d "$depth" -H -i -g "*.PROJECT" "$dir" | sed 's/[.]PROJECT$//'
}

find-projects-in-home()
{
  find-projects "$HOME" "$1"
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

git-clone()
{
  local repo="$1"
  local dst="$2"

  [[ -z $repo ]] && echo "No repository URL provided" && return 1
  [[ -z $dst ]] && echo "No destination directory provided" && return 1

  git clone "$repo" "$dst"
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

cp-template()
{
  local fname="$1"
  local dst="${2:-}"
  fname="~/Templates/$fname"

  if [[ -f $fname  ]]; then
    echo "Invalid template filename: $1"
    return 1
  fi

  cp -v "$fname" "$dst"
}

user-cp-profile()
{
  local src="${1:-default}"
  local dst="${2:-./}"
  src="$MY_DIR/nix/${src}.nix"

  [[ ! -f $src ]] && echo "Nonexistent nix profile" && return 1
  [[ ! -d $dst ]] && echo "Nonexistent directory $dst" && return 1

  cp "$src" "$dst/"
}

loconvert()
{
  [[ -z $1 ]] && echo "No type defined" && return 1
  [[ -z $2 ]] && echo "No filename provided" && return 1
  [[ ! -f $2 ]] && echo "Nonexistent file: $2" && return 1
  libreoffice --convert-to "$1" "$2"
}

json2nix()
{
  [[ -z $1 ]] && echo "No JSON file given" && return 1
  [[ ! -f $1 ]] && echo "Nonexistent JSON file: $1" && return 1

  local path="$(realpath "$1")"
  nix eval --impure --expr "builtins.fromJSON (builtins.readFile \"$path\")" | nixfmt -
}
