{ pkgs, hostname ? "nixos", ... }: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
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
    grimblast wl-clipboard cliphist brightnessctl awww matugen
    nautilus gvfs pavucontrol pwvucontrol
    impala bluetui playerctl hyprlock hypridle
    pipewire wireplumber blueman libnotify mako
    adwaita-qt adwaita-qt6 papirus-icon-theme papirus-folders
    obs-studio bibata-cursors fastfetch btop vscode gcc
    spotify fish starship loupe zathura libreoffice
    standardnotes mpv gsettings-desktop-schemas
    hplipWithPlugin glib vesktop
    ollama codex
    qgis fzf
    eza bat zoxide
    direnv nix-direnv
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    inter roboto material-symbols
  ];

  hardware.graphics.enable        = true;
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver intel-vaapi-driver
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

  services.ollama = {
    enable = true;
    package = if hostname == "desktop" then pkgs.ollama-cuda else pkgs.ollama;
  };

}
