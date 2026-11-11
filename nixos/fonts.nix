{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
    fontconfig = {
      enable = true;
      antialias = true;
      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };
      hinting = {
        enable = true;
        style = "slight";
        autohint = false;
      };
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
      nerd-fonts.hack
      nerd-fonts.liberation
      nerd-fonts.ubuntu
    ];
  };
}
