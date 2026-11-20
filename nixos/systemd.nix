{
  pkgs,
  ...
}:
let
  mkService =
    {
      unit,
      service,
      wants,
    }:
    {
      unitConfig = unit;
      serviceConfig = service;
      wantedBy = wants;
    };
  myServices = {
    mako = mkService {
      unit = {
        Description = "Mako notification daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=sway";
      };
      service = {
        ExecStart = "${pkgs.mako}/bin/mako";
        Restart = "on-failure";
      };
      wants = [ "graphical-session.target" ];
    };
    swayosd-server = mkService {
      unit = {
        Description = "SwayOSD server";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
        ConditionEnvironment = "XDG_CURRENT_DESKTOP=sway";
      };
      service = {
        ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
        Restart = "on-failure";
      };
      wants = [ "graphical-session.target" ];
    };
  };
in
{
  systemd = {
    user.services = myServices;
    sleep.settings.Sleep = {
      "AllowSuspend" = "no";
      "AllowHibernation" = "no";
      "AllowHybridSleep" = "no";
      "AllowSuspendThenHibernate" = "no";
    };
    targets = {
      sleep.enable = false;
      suspend.enable = false;
      hibernate.enable = false;
      hybrid-sleep.enable = false;
    };
    tmpfiles.rules = [
      "L+ /opt/rocm - - - - ${pkgs.rocmPackages.clr}"
      "w /sys/devices/system/cpu/cpufreq/boost - - - - 0"
    ];
  };
}
