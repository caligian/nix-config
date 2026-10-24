#!/usr/bin/env bash

set -euo pipefail
if ! command -v git >/dev/null || ! command -v ssh-keygen >/dev/null || ! command -v mkpasswd >/dev/null; then
  exec nix-shell -p git openssh mkpasswd --run "$(printf 'bash %q' "$(realpath "$0")") $*"
fi

USER_NAME="${USER_NAME:-Kerambit}"
REPO="${REPO:-git@github.com:caligian/nix-config.git}"
REPO_DIR="$HOME/.user"
CHANNEL="${CHANNEL:-nixos-26.05}"
SECRET_FILE="/etc/secrets/${USER_NAME}"
SSH_KEY="$HOME/.ssh/id_ed25519"

log()  { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN: %s\033[0m\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }
confirm() { read -rp "$1 [y/N] " a; [[ ${a:-N} =~ ^[Yy]$ ]]; }

[[ $EUID -ne 0 ]] || die "Run as your normal user, not root."
[[ "$USER_NAME" == "$(id -un)" ]] || die "USER_NAME=$USER_NAME but running as $(id -un). configuration.nix hardcodes user='Kerambit'."
[[ "$CHANNEL" =~ ^nixos-[0-9]+\.[0-9]+$ ]] || die "Bad channel name: $CHANNEL"
[[ -f /etc/nixos/configuration.nix ]] || die "/etc/nixos/configuration.nix missing — is NixOS installed?"

log "Ensuring root channel -> $CHANNEL"
if ! sudo nix-channel --list | grep -qE "^nixos\s+https://nixos.org/channels/${CHANNEL}$"; then
  sudo nix-channel --add "https://nixos.org/channels/${CHANNEL}" nixos
fi
sudo nix-channel --update

log "Ensuring SSH key for GitHub"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

if [[ ! -f "$SSH_KEY" ]]; then
  ssh-keygen -t ed25519 -C "${USER_NAME}@$(hostname)" -f "$SSH_KEY" -N ""
else
  echo "Key exists: $SSH_KEY"
fi
chmod 600 "$SSH_KEY"

grep -q "github.com" "$HOME/.ssh/known_hosts" 2>/dev/null || \
  ssh-keyscan github.com >> "$HOME/.ssh/known_hosts" 2>/dev/null || true

echo
echo "=== Add this public key to https://github.com/settings/keys ==="
cat "$SSH_KEY.pub"
echo "================================================================"
confirm "Have you added the key to GitHub?" || die "Add the key, then re-run."

ssh -T git@github.com 2>&1 | grep -q "Successfully authenticated" \
  && echo "GitHub auth: OK" \
  || warn "GitHub auth test inconclusive; clone may still work if repo is public"

log "Cloning $REPO -> $REPO_DIR"

if [[ -d "$REPO_DIR/.git" ]]; then
  git -C "$REPO_DIR" pull --ff-only || warn "pull failed; using existing tree"
else
  git clone "$REPO" "$REPO_DIR"
fi

[[ -f "$REPO_DIR/.bashrc" ]] || die "$REPO_DIR/.bashrc missing from repo"
[[ -f "$REPO_DIR/nixos/configuration.nix" ]] || die "$REPO_DIR/nixos/configuration.nix missing"

log "Linking ~/.bashrc -> $REPO_DIR/.bashrc"
if [[ -f "$HOME/.bashrc" && ! -L "$HOME/.bashrc" ]]; then
  cp -v "$HOME/.bashrc" "$HOME/.bashrc.pre-bootstrap.$(date +%s)"
fi
ln -sfn "$REPO_DIR/.bashrc" "$HOME/.bashrc"

log "Copying nix modules to /etc/nixos"
[[ -f "$REPO_DIR/nixos/hardware-configuration.nix" ]] && \
  die "hardware-configuration.nix must NOT be in the repo; remove it and re-run."

for f in "$REPO_DIR/nixos/"*.nix; do
  [[ "$(basename "$f")" == "hardware-configuration.nix" ]] && continue
  sudo cp -v "$f" /etc/nixos/
done

sudo rm -rf /etc/nixos/pkgs
sudo mkdir -p /etc/nixos/pkgs

if compgen -G "$REPO_DIR/nixos/pkgs/*.nix" >/dev/null; then
  for f in "$REPO_DIR/nixos/pkgs/"*.nix; do
    sudo cp -v "$f" /etc/nixos/pkgs/
  done
fi

log "Creating $SECRET_FILE"
if [[ -f "$SECRET_FILE" ]]; then
  warn "$SECRET_FILE exists; skipping."
else
  sudo mkdir -p /etc/secrets
  sudo chmod 700 /etc/secrets
  hash=$(mkpasswd -m yescrypt)
  [[ "$hash" == \$y\$* ]] || die "Unexpected hash format: ${hash:0:8}..."
  printf '%s\n' "$hash" | sudo tee "$SECRET_FILE" >/dev/null
  sudo chmod 600 "$SECRET_FILE"
  sudo chown root:root "$SECRET_FILE"
fi
[[ -s "$SECRET_FILE" ]] || die "$SECRET_FILE empty or missing after write"

log "First rebuild: sudo nixos-rebuild switch"
sudo nixos-rebuild switch --show-trace

log "Bootstrap complete."
