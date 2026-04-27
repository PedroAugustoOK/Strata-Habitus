{ pkgs, lib, hostname ? "nixos", hostMeta ? {}, ... }:
let
  graphics = hostMeta.graphics or "generic";
  useIntelMedia = builtins.elem graphics [ "intel" "hybrid-intel-nvidia" ];
  appsStatePath = ../state/apps.nix;
  colloidIconTheme = pkgs.colloid-icon-theme.override {
    schemeVariants = [ "default" ];
    colorVariants = [ "default" "pink" "green" "grey" "purple" "orange" ];
  };
  strataUserApps =
    if builtins.pathExists appsStatePath then
      import appsStatePath { inherit pkgs; }
    else
      [];
in {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = (with pkgs; [
    (stdenv.mkDerivation {
      pname = "sddm-theme-strata";
      version = "1.0";
      src = ./sddm-theme;
      dontBuild = true;
      installPhase = ''
        mkdir -p $out/share/sddm/themes/strata
        cp Main.qml metadata.desktop theme.conf $out/share/sddm/themes/strata/
        cp ${../wallpaper.jpg} $out/share/sddm/themes/strata/background.jpg
      '';
    })
    git wget curl neovim nodejs_22 kitty chromium quickshell
    (pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
      p.nix p.lua p.bash p.python p.javascript p.typescript
      p.json p.yaml p.toml p.markdown p.html p.css p.c p.cpp
      p.rust p.go p.fish
    ]))
    grimblast wl-clipboard cliphist brightnessctl awww matugen satty
    nautilus gvfs pavucontrol pwvucontrol
    impala bluetui playerctl hyprlock hypridle
    pipewire wireplumber blueman libnotify mako
    adwaita-qt adwaita-qt6 gnome-themes-extra colloidIconTheme
    obs-studio bibata-cursors fastfetch btop vscode gcc
    spotify fish starship loupe zathura libreoffice
    gnome-calculator file-roller gnome-clocks gnome-calendar
    gnome-control-center simple-scan system-config-printer thunderbird
    standardnotes mpv gsettings-desktop-schemas
    hplipWithPlugin glib imagemagick
    codex
    qgis fzf
    lm_sensors
    eza bat zoxide
    direnv nix-direnv
    protonmail-desktop protonmail-bridge-gui
    proton-pass proton-authenticator
    gnome-keyring seahorse
  ]) ++ strataUserApps;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter roboto material-symbols
  ];

  hardware.graphics.enable        = true;
  hardware.graphics.extraPackages = with pkgs;
    lib.optionals useIntelMedia [
      intel-media-driver
      intel-vaapi-driver
    ];

  nix.settings.experimental-features  = [ "nix-command" "flakes" ];
  nix.settings.keep-outputs            = true;
  nix.settings.keep-derivations        = true;
  nix.settings.auto-optimise-store     = true;

  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 30d";
  };

}
