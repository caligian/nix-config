{ ... }: {
  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults timestamp_timeout=15
      '';
    };
    polkit.enable = true;
    pam.services.gdm.enableGnomeKeyring = true;
  };
}
