{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
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
      cantarell-fonts # GNOME default font
      dejavu_fonts
      font-awesome
      inconsolata
      inconsolata-lgc
    ];
  };
}
