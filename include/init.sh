stty -ixon
unset TEMP TMP TEMPDIR TMPDIR
TMPDIR="$(mktemp -d /tmp/nix-shell-XXXXXX)"; export TMPDIR
gsettings set org.gnome.mutter.keybindings switch-monitor "[]" &>/dev/null
