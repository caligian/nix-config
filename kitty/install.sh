#!/usr/bin/env bash

if [[ ! -d ~/.config/kitty ]]; then
  mkdir -p ~/.config/kitty
fi

cp ~/.config/kitty/{kitty.conf,kitty.conf.bak}
cp $MY_DIR/kitty/kitty.conf ~/.config/kitty/kitty.conf
