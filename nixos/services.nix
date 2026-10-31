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
      displayManager.lightdm.enable = false;
      videoDrivers = [ "amdgpu" ];
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
    };
    desktopManager = {
      gnome.enable = true;
      plasma6.enable = false;
      budgie.enable = false;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
      wireplumber.extraConfig = {
        "bluetoothEnhancements" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.roles" = [
              "hsp_hs"
              "hsp_ag"
              "hfp_hf"
              "hfp_ag"
              "a2dp_sink"
              "a2dp_source"
            ];
          };
        };
      };
    };
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
