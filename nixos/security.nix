{ ... }: {
  security = {
    sudo = {
      enable = true;
      extraConfig = ''
        Defaults timestamp_timeout=15
        Defaults env_keep += "NIX_PATH"
      '';
    };
    polkit.enable = true;
    pam.services.gdm.enableGnomeKeyring = true;
  };
}
