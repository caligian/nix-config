# Setting up user password after the system is functional after first install
# openssl passwd -6
# sudo nano /etc/secrets/Kerambit
# sudo chown root:root /etc/secrets/Kerambit
# sudo chmod 600 /etc/secrets/Kerambit
{
  config,
  lib,
  pkgs,
  ...
}:
let
  user = "Kerambit";
  imports = [ "/etc/nixos/hardware-configuration.nix" ];
  importModule =
    name:
    import "/etc/nixos/${name}.nix" {
      inherit
        pkgs
        config
        lib
        user
        ;
    };
  qt = importModule "qt";
  nixpkgs = importModule "nixpkgs";
  services = importModule "services";
  security = importModule "security"; 
  fonts = importModule "fonts";
  boot = importModule "boot";
  xdg = importModule "xdg";
  hardware = importModule "hardware";
  networking = importModule "networking";
  systemd = importModule "systemd";
  programs = importModule "programs";
  environment = importModule "environment";
  userConfig = {
    isNormalUser = true;
    hashedPasswordFile = "/etc/secrets/${user}";
    extraGroups = [
      "wheel"
      "network"
      "video"
      "sudo"
    ];
    packages = with pkgs; [ tree ];
  };
in
{
  imports = imports;

  # Virtualization
  virtualisation.waydroid.enable = false;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  # Datetime settings
  time.timeZone = "Asia/Kolkata";

  # Locale stuff
  i18n = {
    defaultLocale = "en_US.UTF-8";
    inputMethod = {
      enable = false;
      type = "null";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  # User setup
  users.users.${user} = userConfig;

  # Nix settings
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # DO NOT TOUCH
  system.stateVersion = "25.11";
}
// programs
// services
// security
// environment
// boot
// xdg
// hardware
// networking
// nixpkgs
// qt
// fonts
// systemd
