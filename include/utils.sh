symlink()
{
  [[ -z $1 ]] && echo "No path provided" && return 1
  [[ -z $2 ]] && echo "No link name provided" && return 1
  ln -sf "$1" "$2"
}

user-cp()
{
  [[ -z $1 ]] && echo "No path provided" && return 1
  local src="~/.user/$1"
  local dst="${2:-./$1}"

  [[ ! -e $src ]] && echo "Invalid path $src" && return 1
  cp -r "$src" "$dst" && return 0 || return 1
}

user-ln()
{
  [[ -z $1 ]] && echo "No path provided" && return 1
  local src="~/.user/$1"
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

git-status()
{
  git status -s
}

mapkey()
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
    echo "Nonexistent template: $fname"
    return 1
  fi

  cp -v "$fname" "$dst"
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

csv2xlsx()
{
  local filename="$1"
  [[ ! -f $filename ]] && echo "Invalid filename: $filename" && return 1
  [[ ! $filename =~ csv$ ]] && echo "Not a CSV file: $filename" && return 1
  loconvert xlsx "$filename" 
}

pdf-merge()
{
  pdfunite "$@"
}

pdf-split()
{
  local src="$1"
  local from="$2"
  local to="$3"
  local dst="${1%%.pdf}-%d.pdf"

  [[ -z $src ]] || [[ ! -f $src ]] && echo "Nonexistent file: $src" && return 1
  [[ -z $from ]] && echo "No first page provided" && return 1
  [[ -z $to ]] && echo "No last page provided" && return 1

  pdfseparate -f $from -l $to "$src" "$dst"
}

pdf-slice()
{
  local src="$1"
  local from="$2"
  local to="$3"
  local dst="${src%%.pdf}_$from-$to.pdf"

  [[ -z $src ]] || [[ ! -f $src ]] && echo "Nonexistent file: $src" && return 1
  [[ -z $from ]] && echo "No first page provided" && return 1
  [[ -z $to ]] && echo "No last page provided" && return 1

  qpdf "$src" --pages . "$from"-"$to" -- "$dst"
}

pdf-ocr()
{
  local langs="${1:-eng}"
  local src="$2"
  local dst="${2%%.pdf}-ocr.pdf"

  [[ -z $src ]] || [[ ! -f $src ]] && echo "Nonexistent file: $src" && return 1

  ocrmypdf -l "$langs" --force-ocr "$src" "$dst"
}

pdf-ocr-rm()
{
  local src="$1"
  local dst="${1%%.pdf}-no-ocr.pdf"
  [[ -z $src ]] || [[ ! -f $src ]] && echo "Nonexistent file: $src" && return 1
  ocrmypdf --mode strip "$src" "$dst"
}

pdf-text()
{
  local src="$1"
  [[ -z $src ]] || [[ ! -f $src ]] && echo "Nonexistent file: $src" && return 1
  shift 1
  pdftotext -layout "$src" "$@"
}

pdf-chunk()
{
  local src="${1-}"
  [[ -f "$src" ]] || { echo "Nonexistent file: ${src:-<empty>}" >&2; return 1; }

  local size="${2:-10}"
  local total=$(pdfinfo "$src" | awk '/^Pages:/ {print $2}')

  [[ -n "$total" ]] || { echo "Could not determine page count" >&2; return 1; }

  local from=1
  while (( from <= total )); do
    local to=$(( from + size - 1 ))
    (( to > total )) && to=$total
    pdf-slice "$src" "$from" "$to"
    (( from += size ))
  done
}
