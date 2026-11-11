{
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_zen;
    kernelParams = [
      "amdgpu.sg_display=0"
      "amdgpu.abmlevel=0"
      "amdgpu.dcdebugmask=0x10"
      "amd_pstate=disable"
      "nohibernate"
      "acpi_enforce_resources=lax"
      "usbcore.autosuspend=-1"
      "iommu=pt"
      "processor.max_cstate=5"
      "amdgpu.runpm=0"
      "usbcore.quirks=36ae:feac:k"
      "acpi=force"
      "drm.force_dvi_monitor=1"
    ];
    extraModprobeConfig = "";
    initrd.kernelModules = [ ];
  };
}
