{ config, pkgs, lib, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  # Boot
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Rede
  networking.hostName              = "nixos";
  networking.networkmanager.enable = true;

  # Locale
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

  # Teclado
  services.xserver.xkb = { layout = "br"; variant = ""; };
  console.keyMap = "br-abnt2";

  # Usuário
  users.users.ankh = {
    isNormalUser = true;
    description  = "Pedro Augusto";
    extraGroups  = [ "networkmanager" "wheel" ];
    packages     = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  # Pacotes
  environment.systemPackages = with pkgs; [
    git wget curl neovim
    networkmanager
    kitty
    chromium
    quickshell
    grimblast
    wl-clipboard
    cliphist
    brightnessctl
    swww
    matugen
    nautilus
    gvfs
    pavucontrol
    playerctl
    hyprlock
    hypridle
    pipewire
    wireplumber
    blueman
    libnotify
    nautilus
    gvfs
    adwaita-qt
    adwaita-qt6
  ];

  # Hyprland
  programs.hyprland.enable        = true;
  programs.hyprland.xwayland.enable = true;

  # Portais Wayland
  xdg.portal.enable        = true;
  xdg.portal.extraPortals  = [ pkgs.xdg-desktop-portal-hyprland ];

  # Login
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd start-hyprland";
      user    = "greeter";
    };
  };

  # Fontes
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter
  ];

  # GPU Intel
  hardware.graphics.enable        = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    intel-vaapi-driver
  ];

  # Nix
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Stylix
  stylix = {
    enable   = true;
    image    = ./wallpaper.jpg;
    polarity = "dark";
  };
 
  # Audio
security.rtkit.enable = true;
services.pipewire = {
  enable            = true;
  alsa.enable       = true;
  alsa.support32Bit = true;
  pulse.enable      = true;
  wireplumber.enable = true;
};

  # Bluetooth
hardware.bluetooth.enable      = true;
hardware.bluetooth.powerOnBoot = true;
services.blueman.enable        = true;

#Nautilus
services.gvfs.enable = true;

#Tema QT
environment.sessionVariables = {
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
};

qt = {
  enable = true;
  style = "adwaita-dark";
  platformTheme = lib.mkForce "gnome";
};

  system.stateVersion = "25.11";
}
