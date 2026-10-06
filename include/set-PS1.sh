#!/usr/bin/bash

[[ -z $1 ]] && echo "No filename provided" && exit 1
dir="$(dirname \"$1\")"
name="$(basename \"$dir\")"
