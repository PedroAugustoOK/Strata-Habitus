{ config, pkgs, lib, username ? "ankh", hostMeta ? {}, ... }:
let
  desktopMeta = hostMeta.desktop or {};
  loginManagerMeta = desktopMeta.loginManager or {};
  loginManagerEnabled = loginManagerMeta.enable or true;
in {
  programs.nix-ld.enable  = true;
  programs.ssh.startAgent = true;
  programs.hyprland.enable          = true;
  programs.hyprland.xwayland.enable = true;
  programs.hyprland.withUWSM        = false;
  programs.uwsm.enable              = lib.mkForce false;
  programs.dconf.enable             = true;

  xdg.portal.enable       = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  services.displayManager.sddm = {
    enable         = loginManagerEnabled;
    wayland.enable = true;
    theme          = "strata";
    settings.Theme.ThemeDir    = "/var/lib";
    settings.Theme.CursorTheme = "Bibata-Modern-Classic";
    settings.Users.RememberLastSession = false;
    settings.Users.RememberLastUser    = false;
    package = pkgs.kdePackages.sddm.override {
      sddm-unwrapped = pkgs.kdePackages.sddm.unwrapped.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          ln -s sddm-greeter-qt6 $out/bin/sddm-greeter
        '';
      });
    };
    extraPackages = with pkgs.kdePackages; [ qtdeclarative qtsvg ];
  };
  services.displayManager.defaultSession = lib.mkIf loginManagerEnabled "hyprland";
  services.displayManager.sessionPackages = lib.mkIf loginManagerEnabled (lib.mkForce [ config.programs.hyprland.package ]);

  services.gvfs.enable                 = true;
  services.power-profiles-daemon.enable = true;
  services.flatpak.enable               = true;
  services.printing.enable              = true;
  services.printing.drivers             = [ pkgs.hplipWithPlugin ];
  services.udev.packages                = [ pkgs.hplipWithPlugin ];

  environment.sessionVariables = {
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    NIXOS_OZONE_WL                      = "1";
    XCURSOR_THEME                       = "Bibata-Modern-Classic";
    XCURSOR_SIZE                        = "24";
    STARSHIP_CONFIG                     = "/home/${username}/dotfiles/generated/starship/starship.toml";
  };

  qt = {
    enable        = true;
    style         = "adwaita-dark";
    platformTheme = lib.mkForce "gnome";
  };

  # Cria /var/lib/strata e copia arquivos do tema SDDM
  system.activationScripts.strataDir = lib.mkIf loginManagerEnabled ''
    mkdir -p /var/lib/strata
    chmod 755 /var/lib/strata
    rm -f /var/lib/sddm/state.conf
    cp /run/current-system/sw/share/sddm/themes/strata/Main.qml \
       /var/lib/strata/Main.qml 2>/dev/null || true
    cp -n /run/current-system/sw/share/sddm/themes/strata/metadata.desktop \
       /var/lib/strata/metadata.desktop 2>/dev/null || true
  '';
}
