{ config, osConfig, pkgs, lib, username ? "ankh", ... }:
let
  dotfiles = "/home/${username}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  hostname = osConfig.networking.hostName;
in {
  home.enableNixpkgsReleaseCheck = false;
  home.username      = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "25.11";
  programs.home-manager.enable = true;

  # Tema GTK + ícones (propaga via gsettings pro qt.platformTheme=gnome)
  gtk = {
    enable = true;
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size    = 24;
    };
  };

  # btop declarativo: color_theme fixo em "strata" (~/.config/btop/btop.conf
  # fica read-only no /nix/store). set-theme.sh só reescreve strata.theme
  # em ~/.config/btop/themes/, que continua writable.
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "strata";
      theme_background = true;
    };
  };

  # Entrada custom pro nvim: Terminal=false + kitty explícito, pra Nautilus/xdg-open
  # não depender de "default terminal" do ambiente (que no Hyprland puro não existe).
  xdg.desktopEntries.nvim-kitty = {
    name       = "Neovim (kitty)";
    genericName = "Editor de texto";
    exec       = "kitty -e nvim %F";
    terminal   = false;
    icon       = "nvim";
    categories = [ "Utility" "TextEditor" ];
    mimeType   = [ "text/plain" "text/markdown" "text/x-shellscript" ];
  };

  # Associações de arquivo (docs, txt, PDF, imagens, mídia)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/plain"                  = "nvim-kitty.desktop";
      "application/pdf"             = "org.pwmt.zathura.desktop";
      "image/jpeg"                  = "org.gnome.Loupe.desktop";
      "image/png"                   = "org.gnome.Loupe.desktop";
      "image/gif"                   = "org.gnome.Loupe.desktop";
      "image/webp"                  = "org.gnome.Loupe.desktop";
      "image/bmp"                   = "org.gnome.Loupe.desktop";
      "image/svg+xml"               = "org.gnome.Loupe.desktop";
      "video/mp4"                   = "mpv.desktop";
      "video/x-matroska"            = "mpv.desktop";
      "video/webm"                  = "mpv.desktop";
      "video/quicktime"             = "mpv.desktop";
      "audio/mpeg"                  = "mpv.desktop";
      "audio/flac"                  = "mpv.desktop";
      "audio/ogg"                   = "mpv.desktop";
      "audio/wav"                   = "mpv.desktop";
      "inode/directory"             = "org.gnome.Nautilus.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"       = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
      "application/msword"           = "writer.desktop";
      "application/vnd.ms-excel"     = "calc.desktop";
      "application/vnd.ms-powerpoint" = "impress.desktop";
      "application/vnd.oasis.opendocument.text"         = "writer.desktop";
      "application/vnd.oasis.opendocument.spreadsheet"  = "calc.desktop";
      "application/vnd.oasis.opendocument.presentation" = "impress.desktop";
    };
  };

  # Hyprland (monitores vêm do arquivo por host)
  xdg.configFile."hypr/hyprland.conf".source = link "hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source  = link "generated/hypr/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source  = link "hypridle.conf";
  xdg.configFile."hypr/monitors.conf".source  = link "hosts/${hostname}/hyprland-monitors.conf";

  # Shell & terminal
  xdg.configFile."fish/config.fish".source = link "fish/config.fish";
  xdg.configFile."kitty/kitty.conf".source = link "kitty/kitty.conf";
  xdg.configFile."kitty/strata-theme.conf".source = link "generated/kitty/colors.conf";

  # Desktop UI
  xdg.configFile."quickshell".source = link "quickshell";
  xdg.configFile."mako/config".source = link "generated/mako/config";

  # Editor
  xdg.configFile."nvim".source = link "nvim";

  # Ferramentas
  xdg.configFile."fastfetch".source = link "fastfetch";

  # Git e SSH
  home.file.".gitconfig".source    = link "git/config";
  home.file.".ssh/config" = {
    source = link "ssh/config";
    force  = true;
  };
}
