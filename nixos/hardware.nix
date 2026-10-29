{ pkgs, ... }:
{
  hardware = {
    acpilight.enable = true;
    enableRedistributableFirmware = true;
    cpu.intel.updateMicrocode = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
      extraPackages32 = with pkgs; [
        driversi686Linux.intel-media-driver
      ];
    };
    bluetooth = {
      enable = true;
      powerOnBoot = false;
    };
  };
}
