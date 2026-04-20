{ pkgs, lib, username ? "ankh", ... }: {
  programs.fish.enable              = true;
  programs.hyprland.enable          = true;
  programs.hyprland.xwayland.enable = true;
  programs.dconf.enable             = true;

  xdg.portal.enable       = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  services.displayManager.sddm = {
    enable         = true;
    wayland.enable = true;
    theme          = "strata";
    settings.Theme.ThemeDir    = "/var/lib";
    settings.Theme.CursorTheme = "Bibata-Modern-Classic";
    package = pkgs.kdePackages.sddm.override {
      sddm-unwrapped = pkgs.kdePackages.sddm.unwrapped.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          ln -s sddm-greeter-qt6 $out/bin/sddm-greeter
        '';
      });
    };
    extraPackages = with pkgs.kdePackages; [ qtdeclarative qtsvg ];
  };

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
    STARSHIP_CONFIG                     = "/home/${username}/dotfiles/starship/starship.toml";
  };

  qt = {
    enable        = true;
    style         = "adwaita-dark";
    platformTheme = lib.mkForce "gnome";
  };

  # Cria /var/lib/strata e copia arquivos do tema SDDM
  system.activationScripts.strataDir = ''
    mkdir -p /var/lib/strata
    chmod 755 /var/lib/strata
    cp /run/current-system/sw/share/sddm/themes/strata/Main.qml \
       /var/lib/strata/Main.qml 2>/dev/null || true
    cp -n /run/current-system/sw/share/sddm/themes/strata/metadata.desktop \
       /var/lib/strata/metadata.desktop 2>/dev/null || true
  '';
}
