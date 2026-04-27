{ config, pkgs, lib, username ? "ankh", hostMeta ? {}, ... }:
let
  desktopMeta = hostMeta.desktop or {};
  loginManagerMeta = desktopMeta.loginManager or {};
  loginManagerEnabled = loginManagerMeta.enable or true;
in {
  programs.nix-ld.enable  = true;
  programs.ssh.startAgent = true;
  programs.steam.enable   = true;
  programs.hyprland.enable          = true;
  programs.hyprland.xwayland.enable = true;
  programs.hyprland.withUWSM        = false;
  programs.uwsm.enable              = lib.mkForce false;
  programs.dconf.enable             = true;
  services.gnome.gcr-ssh-agent.enable = false;
  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;
  security.pam.services.sddm.enableGnomeKeyring  = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "hyprland" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "hyprland" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
        "org.freedesktop.impl.portal.OpenURI" = [ "gtk" ];
      };
    };
  };

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
  system.activationScripts.flatpakFlathub = ''
    if [ -x /run/current-system/sw/bin/flatpak ]; then
      /run/current-system/sw/bin/flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null 2>&1 || true
    fi
  '';
  services.printing.enable              = true;
  services.printing.browsing            = true;
  services.printing.drivers             = [ pkgs.hplipWithPlugin ];
  services.avahi.enable                 = true;
  services.avahi.nssmdns4               = true;
  services.avahi.openFirewall           = true;
  services.ipp-usb.enable               = true;
  hardware.sane.enable                  = true;
  hardware.sane.extraBackends           = [ pkgs.hplipWithPlugin ];
  services.udev.packages                = [
    pkgs.hplipWithPlugin
    pkgs.steam-devices-udev-rules
  ];

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
    cp -f ${./sddm-theme/Main.qml} /var/lib/strata/Main.qml
    cp -f ${./sddm-theme/metadata.desktop} /var/lib/strata/metadata.desktop
    cp -f ${./sddm-theme/theme.conf} /var/lib/strata/theme.conf
    cp -f ${../wallpaper.jpg} /var/lib/strata/background.jpg
  '';
}
