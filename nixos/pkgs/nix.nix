{ pkgs, ... }:
(with pkgs; [
  nix-init
  nix-prefetch-git
  nix-prefetch-github
])
