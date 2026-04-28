{ config, lib, pkgs, ... }:
let
  cfg = config.strata.protonVPNWireGuard;
  toggleScript = pkgs.writeShellScriptBin "protonvpn-wg-toggle" ''
    if systemctl is-active --quiet ${cfg.serviceName}.service; then
      exec sudo systemctl stop ${cfg.serviceName}.service
    else
      exec sudo systemctl start ${cfg.serviceName}.service
    fi
  '';
  upScript = pkgs.writeShellScriptBin "protonvpn-wg-up" ''
    exec sudo systemctl start ${cfg.serviceName}.service
  '';
  downScript = pkgs.writeShellScriptBin "protonvpn-wg-down" ''
    exec sudo systemctl stop ${cfg.serviceName}.service
  '';
  statusScript = pkgs.writeShellScriptBin "protonvpn-wg-status" ''
    exec systemctl status ${cfg.serviceName}.service
  '';
in {
  options.strata.protonVPNWireGuard = {
    enable = lib.mkEnableOption "Proton VPN over WireGuard via wg-quick";

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start the Proton VPN tunnel automatically at boot.";
    };

    serviceName = lib.mkOption {
      type = lib.types.str;
      default = "protonvpn-wg";
      description = "Systemd service name used for the Proton VPN tunnel.";
    };

    configFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/wireguard/protonvpn.conf";
      description = "Absolute path to the WireGuard config downloaded from Proton VPN.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/" cfg.configFile;
        message = "strata.protonVPNWireGuard.configFile must be an absolute path.";
      }
    ];

    networking.resolvconf.enable = lib.mkDefault true;

    environment.systemPackages = [
      toggleScript
      upScript
      downScript
      statusScript
    ];

    systemd.services.${cfg.serviceName} = {
      description = "Proton VPN WireGuard tunnel";
      wantedBy = lib.optional cfg.autoStart "multi-user.target";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up ${cfg.configFile}";
        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down ${cfg.configFile}";
      };
      path = with pkgs; [
        bash
        coreutils
        gnugrep
        iproute2
        iptables
        openresolv
        procps
        wireguard-tools
      ];
    };
  };
}
