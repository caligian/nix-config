{
  pkgs,
  ...
}:
{
  hardware = {
    acpilight.enable = true;
    enableRedistributableFirmware = true;
    amdgpu = {
      initrd.enable = true;
      overdrive.enable = true;
      opencl.enable = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [ mesa ];
      extraPackages32 = with pkgs; [ driversi686Linux.mesa ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
}
