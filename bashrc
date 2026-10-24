#!/bin/bash

set-nix-PS1() {
  [[ -z $1 ]] && echo "No name provided" && return 1
  [[ -z $IN_NIX_SHELL ]] && echo "nix-shell is not running" && return 1

  local name="${1}"
  local GREEN='\[\033[1;92m\]'
  local RESET='\[\033[0m\]'
  local ORANGE='\[\033[38;5;208m\]'
  local YELLOW='\[\033[1;93m\]'

  PS1="${ORANGE}[$name]${YELLOW} {\u}${GREEN} \w > ${RESET}"
}

dev()
{
  if [[ -z $1  ]]; then
    if [[ -f ./shell.nix ]]; then
      nix-shell ./shell.nix
    else
      nix-shell ~/shell.nix
    fi
  elif [[ -f $1  ]]; then
    nix-shell "$1"
  elif [[ -d $1 && -f "$1/shell.nix" ]]; then
    nix-shell "$1/shell.nix"
  fi
}

sys-reload()
{
  sudo nixos-rebuild switch
}

sys-edit()
{
  sudo vi /etc/nixos/configuration.nix
}

sys-rebuild()
{
  local home="$HOME"
  local root="$home/.user/nixos"
  sudo bash -c "cp -v $root/*.nix /etc/nixos/; cp -rv $root/pkgs /etc/nixos/; nixos-rebuild switch"
}

user-profile()
{
  local name="${1:-default}"
  local src="$HOME/.user/nix/profiles/${name}.nix"
  [[ ! -f $src  ]] && echo "$src does not exist" && return 1
  nix-shell "$src"
}

alias ls="/usr/bin/env ls -ctr1p --color=auto"
alias ll="ls -lsh"

# eval "$(direnv hook bash)"
