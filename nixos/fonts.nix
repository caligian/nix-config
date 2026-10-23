{ pkgs, ... }:
{
  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "UbuntuMono Nerd Font"
          "Hack Nerd Font"
          "LiberationMono Nerd Font"
          "Unifont"
          "Inconsolata"
        ];
      };
    };
    packages = with pkgs; [
      font-awesome
      inconsolata
      inconsolata-lgc
    ];
  };
}
