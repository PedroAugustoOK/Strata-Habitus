{ config, pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout                  = 1;

  boot.kernelParams = [
    "quiet" "splash"
    "rd.systemd.show_status=false"
    "rd.udev.log_level=3"
    "udev.log_priority=3"
    "vt.global_cursor_default=0"
    "nowatchdog"
  ];
  boot.initrd.verbose       = false;
  boot.initrd.systemd.enable = true;
  boot.consoleLogLevel      = 0;
  boot.plymouth.enable      = true;

  systemd.services.NetworkManager-wait-online.enable = false;

  networking.hostName              = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone      = "America/Porto_Velho";
  i18n.defaultLocale = "pt_BR.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS        = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT    = "pt_BR.UTF-8";
    LC_MONETARY       = "pt_BR.UTF-8";
    LC_NAME           = "pt_BR.UTF-8";
    LC_NUMERIC        = "pt_BR.UTF-8";
    LC_PAPER          = "pt_BR.UTF-8";
    LC_TELEPHONE      = "pt_BR.UTF-8";
    LC_TIME           = "pt_BR.UTF-8";
  };
  services.xserver.xkb = { layout = "br"; variant = ""; };
  console.keyMap = "br-abnt2";

  users.users.ankh = {
    isNormalUser = true;
    description  = "Pedro Augusto";
    extraGroups  = [ "networkmanager" "wheel" "video" ];
    shell        = pkgs.fish;
    packages     = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    (stdenv.mkDerivation {
      pname = "sddm-theme-strata";
      version = "1.0";
      src = ./modules/sddm-theme;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/sddm/themes/strata
        cp Main.qml metadata.desktop theme.conf $out/share/sddm/themes/strata/
        cp ${./wallpaper.jpg} $out/share/sddm/themes/strata/background.jpg
      '';
    })
    git wget curl neovim networkmanager kitty chromium quickshell
    grimblast wl-clipboard cliphist brightnessctl swww matugen
    nautilus gvfs pavucontrol pwvucontrol
    impala bluetui playerctl hyprlock hypridle
    pipewire wireplumber blueman libnotify
    adwaita-qt adwaita-qt6 papirus-icon-theme
    obs-studio bibata-cursors fastfetch btop vscode gcc
    spotify fish starship loupe zathura libreoffice
    standardnotes mpv gsettings-desktop-schemas
    hplipWithPlugin glib vesktop
  ];

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

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter roboto material-symbols
  ];

  hardware.graphics.enable        = true;
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver intel-vaapi-driver ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable      = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable        = true;
  services.gvfs.enable           = true;
  services.power-profiles-daemon.enable = true;
  services.flatpak.enable        = true;
  services.printing.enable       = true;
  services.printing.drivers      = [ pkgs.hplipWithPlugin ];
  services.udev.packages         = [ pkgs.hplipWithPlugin ];

  environment.sessionVariables = {
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    NIXOS_OZONE_WL                      = "1";
    XCURSOR_THEME                       = "Bibata-Modern-Classic";
    XCURSOR_SIZE                        = "24";
    STARSHIP_CONFIG                     = "/home/ankh/dotfiles/starship/starship.toml";
  };

  qt = {
    enable        = true;
    style         = "adwaita-dark";
    platformTheme = lib.mkForce "gnome";
  };

  security.sudo.extraRules = [
    {
      users = [ "ankh" ];
      commands = [
        { command = "/run/current-system/sw/bin/tee /etc/chromium/policies/managed/strata.json"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/mkdir";  options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/cp";     options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/sed";    options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/tee /var/lib/strata/theme.conf"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  system.activationScripts.strataDir = "mkdir -p /var/lib/strata && chmod 755 /var/lib/strata && cp /run/current-system/sw/share/sddm/themes/strata/Main.qml /var/lib/strata/Main.qml 2>/dev/null || true && cp -n /run/current-system/sw/share/sddm/themes/strata/metadata.desktop /var/lib/strata/metadata.desktop 2>/dev/null || true";

  system.stateVersion = "25.11";
}
