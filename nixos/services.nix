{
  ...
}:
{
  services = {
    geoclue2.enable = false;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        options = "caps:escape";
      };
      desktopManager.cinnamon.enable = false;
      displayManager.lightdm.enable = false;
      videoDrivers = [ "amdgpu" ];
      deviceSection = ''
        Option "VariableRefresh" "false"
      '';
    };
    gnome = {
      gnome-keyring.enable = true;
      gnome-browser-connector.enable = true;
    };
    displayManager = {
      gdm = {
        enable = true;
      };
      sddm = {
        enable = false;
        wayland.enable = false;
      };
      defaultSession = "sway";
    };
    desktopManager = {
      gnome.enable = true;
      budgie.enable = false;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      wireplumber.extraConfig = {
        "50-alsa-default" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "device.name" = "alsa_card.pci-0000_03_00.1";
                }
              ];
              actions = {
                update-props = {
                  "device.disabled" = true;
                };
              };
            }
            {
              matches = [
                {
                  "node.name" = "alsa_output.pci-0000_03_00.6.analog-stereo";
                }
              ];
              actions = {
                update-props = {
                  "priority.session" = 1500;
                  "priority.driver" = 1500;
                };
              };
            }
          ];
        };
        "51-bluez-autoswitch" = {
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = false;
          };
        };
        "52-bluez-priority" = {
          "monitor.bluez.rules" = [
            {
              matches = [
                { "node.name" = "~bluez_output.*"; }
              ];
              actions = {
                update-props = {
                  "priority.session" = 2000;
                };
              };
            }
          ];
        };
        "10-properties" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.codecs" = [
              "ldac"
              "aptx_hd"
              "aptx"
              "aac"
              "sbc_xq"
              "sbc"
            ];
            # If you never use the built-in Bluetooth mic, remove hsp/hfp roles
            "bluez5.roles" = [
              "a2dp_sink"
              "a2dp_source"
            ];
          };
        };
      };
    };
    # auto-cpufreq.enable = true;
    clamav = {
      daemon.enable = true;
      updater.enable = true;
      daemon.settings = {
        LogTime = true;
        LogClean = true;
      };
    };
    printing.enable = true;
    libinput.enable = true;
    avahi.enable = false;
    opensnitch.enable = false;
    logind.settings = {
      Login = {
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };
    };
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*scrolllock*", RUN+="/bin/sh -c 'chmod 666 /sys/class/leds/%k/brightness'"
    '';
  };
}
