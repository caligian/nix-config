{
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "amd_pstate=disable"
      "nohibernate"
      "acpi_enforce_resources=lax"
      "usbcore.autosuspend=-1"
      "iommu=pt"
      "processor.max_cstate=1"
      "usbcore.quirks=36ae:feac:k"
    ];
    extraModprobeConfig = "";
    initrd.kernelModules = [ ];
  };
}
