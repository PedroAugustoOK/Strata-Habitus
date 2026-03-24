{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    extraGroups  = [ "networkmanager" "wheel" ];
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
    nautilus gvfs pavucontrol playerctl hyprlock hypridle
    pipewire wireplumber blueman libnotify
    adwaita-qt adwaita-qt6 papirus-icon-theme
  ];

  programs.hyprland.enable          = true;
  programs.hyprland.xwayland.enable = true;
  programs.dconf.enable             = true;

  xdg.portal.enable       = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];

  services.displayManager.sddm = {
    enable         = true;
    wayland.enable = true;
    theme          = "strata";
    package = pkgs.kdePackages.sddm.override {
      sddm-unwrapped = pkgs.kdePackages.sddm.unwrapped.overrideAttrs (old: {
        postInstall = old.postInstall + ''
          ln -s sddm-greeter-qt6 $out/bin/sddm-greeter
        '';
      });
    };
    extraPackages = with pkgs.kdePackages; [ qtdeclarative qtsvg ];
  };

  fonts.packages = with pkgs; [ nerd-fonts.jetbrains-mono inter ];

  hardware.graphics.enable        = true;
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver intel-vaapi-driver ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  stylix = {
    enable   = true;
    image    = ./wallpaper.jpg;
    polarity = "dark";
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable             = true;
    alsa.enable        = true;
    alsa.support32Bit  = true;
    pulse.enable       = true;
    wireplumber.enable = true;
  };

  hardware.bluetooth.enable      = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable        = true;
  services.gvfs.enable           = true;

  environment.sessionVariables = {
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    NIXOS_OZONE_WL                      = "1";
  };

  qt = {
    enable       = true;
    style        = "adwaita-dark";
    platformTheme = lib.mkForce "gnome";
  };

  boot.kernelParams    = [ "quiet" "splash" ];
  boot.initrd.verbose  = false;
  boot.consoleLogLevel = 0;

  system.stateVersion = "25.11";
}
