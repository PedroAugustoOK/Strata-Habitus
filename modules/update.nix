{ pkgs, lib, hostMeta ? {}, hostname ? "nixos", ... }:
let
  updatesMeta = hostMeta.updates or {};
  updatesEnabled = updatesMeta.enable or true;
  autoUpdates = updatesMeta.auto or false;
  releaseRepo = updatesMeta.repo or "PedroAugustoOK/Strata-Habitus";
  releaseChannel = updatesMeta.channel or "stable";
  onBootDelay = updatesMeta.onBootSec or "30min";
  updateInterval = updatesMeta.onUnitActiveSec or "12h";
in
lib.mkIf updatesEnabled {
  systemd.services.strata-update = {
    description = "Strata Habitus channel update";
    path = [
      pkgs.coreutils
      pkgs.curl
      pkgs.git
      pkgs.gnugrep
      pkgs.nix
      pkgs.shadow
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/strata-update.sh";
    };
  };

  systemd.timers.strata-update = lib.mkIf autoUpdates {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = onBootDelay;
      OnUnitActiveSec = updateInterval;
    };
  };

  environment.etc."strata-release.conf".text = ''
    STRATA_UPDATE_REPO=${releaseRepo}
    STRATA_UPDATE_CHANNEL=${releaseChannel}
    STRATA_UPDATE_HOST=${hostname}
  '';

  environment.etc."strata-update.sh" = {
    mode = "0755";
    source = ../strata-update.sh;
  };
}
