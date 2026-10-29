# Setting up user password after the system is functional after first install
# openssl passwd -6
# sudo nano /etc/secrets/Kerambit
# sudo chown root:root /etc/secrets/Kerambit
# sudo chmod 600 /etc/secrets/Kerambit
{
  # config,
  lib,
  pkgs,
  ...
}:
let
  user = "Kerambit";
  imports = [ "/etc/nixos/hardware-configuration.nix" ];
  admin = import "/etc/nixos/admin.nix" { inherit user pkgs lib; };
  qt = import "/etc/nixos/qt.nix" { };
  nixpkgs = import "/etc/nixos/nixpkgs.nix" { };
  services = import "/etc/nixos/services.nix" { };
  security = import "/etc/nixos/security.nix" { };
  fonts = import "/etc/nixos/fonts.nix" { inherit pkgs; };
  boot = import "/etc/nixos/boot.nix" { inherit pkgs; };
  xdg = import "/etc/nixos/xdg.nix" { inherit pkgs; };
  hardware = import "/etc/nixos/hardware.nix" { inherit pkgs; };
  networking = import "/etc/nixos/networking.nix" { inherit user; };
  systemd = import "/etc/nixos/systemd.nix" { inherit pkgs; };
  programs = import "/etc/nixos/programs.nix" { inherit user lib pkgs; };
  environment = import "/etc/nixos/environment.nix" { inherit user lib pkgs; };
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
// fonts
// boot
// xdg
// hardware
// networking
// nixpkgs
// qt
// systemd
