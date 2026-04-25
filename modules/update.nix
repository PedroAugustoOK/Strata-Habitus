{ pkgs, ... }: {
  systemd.services.strata-update = {
    description = "Strata Habitus auto-update";
    path        = [ pkgs.curl pkgs.git pkgs.nix ];
    serviceConfig = {
      Type       = "oneshot";
      ExecStart  = "/etc/strata-update.sh";
    };
  };

  systemd.timers.strata-update = {
    wantedBy    = [ "timers.target" ];
    timerConfig = {
      OnBootSec       = "30min";
      OnUnitActiveSec = "12h";
    };
  };

  environment.etc."strata-update.sh" = {
    mode   = "0755";
    source = ../strata-update.sh;
  };
}
