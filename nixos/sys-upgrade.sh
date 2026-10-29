#!/usr/bin/env bash

VERSION=26.05
URL="https://channels.nixos.org/nixos-$VERSION"
ADMIN_DIR=${ADMIN_DIR:-$HOME/.user}

if [[ ! -d $ADMIN_DIR ]]; then
  echo "Please run 'git clone https://www.github.com/caligian/nix-config \$USER'" 
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  exec sudo -E "$0" "$@"
fi

nix-channel --add "$URL" nixos &>/dev/null

if ! nix-channel --list | grep -q "$VERSION"; then
  echo "Could not add channel @ $URL"
  exit 1
fi

ls /etc/nixos |\
  grep -v hardware-configuration.nix |\
  xargs -i{} -d$'\n' sudo rm -r /etc/nixos/{}

if cp -r $ADMIN_DIR/nixos/* /etc/nixos/; then
  nixos-rebuild switch
fi
