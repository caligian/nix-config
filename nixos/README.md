# Update the channel to nix 26.05 to prevent confusion and settings nonsense
```
sudo nix-channel --remove nixos
sudo nix-channel --add https://channels.nixos.org/nixos-26.05 nixpkgs
sudo nix-channel --update

```
