{ config, osConfig, pkgs, lib, username ? "ankh", hostMeta, ... }:
let
  dotfiles = "/home/${username}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
  hostname = osConfig.networking.hostName;
  colloidIconTheme = pkgs.colloid-icon-theme.override {
    schemeVariants = [ "default" ];
    colorVariants = [ "default" "pink" "green" "grey" "purple" "orange" ];
  };
  archiveMimeTypes = [
    "application/bzip2"
    "application/gzip"
    "application/vnd.android.package-archive"
    "application/vnd.debian.binary-package"
    "application/vnd.ms-cab-compressed"
    "application/vnd.rar"
    "application/x-7z-compressed"
    "application/x-7z-compressed-tar"
    "application/x-archive"
    "application/x-arj"
    "application/x-bzip"
    "application/x-bzip-compressed-tar"
    "application/x-compressed-tar"
    "application/x-cpio"
    "application/x-deb"
    "application/x-gzip"
    "application/x-java-archive"
    "application/x-lha"
    "application/x-lhz"
    "application/x-lrzip"
    "application/x-lrzip-compressed-tar"
    "application/x-lz4"
    "application/x-lzip"
    "application/x-lzip-compressed-tar"
    "application/x-lzma"
    "application/x-lzma-compressed-tar"
    "application/x-lzop"
    "application/x-rar"
    "application/x-rar-compressed"
    "application/x-rpm"
    "application/x-source-rpm"
    "application/x-tar"
    "application/x-tarz"
    "application/x-tzo"
    "application/x-war"
    "application/x-xz"
    "application/x-xz-compressed-tar"
    "application/x-zip"
    "application/x-zip-compressed"
    "application/x-zstd-compressed-tar"
    "application/zip"
    "application/zstd"
  ];
  archiveExtractHere = pkgs.writeShellScriptBin "strata-extract-here" ''
    set -u

    status=0
    for archive in "$@"; do
      [ -f "$archive" ] || continue

      archive_dir="$(${pkgs.coreutils}/bin/dirname "$archive")"
      archive_name="$(${pkgs.coreutils}/bin/basename "$archive")"

      (
        cd "$archive_dir" || exit 1
        ${pkgs.file-roller}/bin/file-roller --extract-here "$archive_name"
      ) || status=$?
    done

    exit "$status"
  '';
in {
  home.enableNixpkgsReleaseCheck = false;
  home.username      = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "25.11";
  programs.home-manager.enable = true;

  home.activation.strataBootstrap = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    DOTFILES="${config.home.homeDirectory}/dotfiles"
    STATE_DIR="$DOTFILES/state"
    GENERATED_DIR="$DOTFILES/generated"

    mkdir -p "$STATE_DIR" "$GENERATED_DIR"

    if [ ! -f "$STATE_DIR/current-theme.json" ]; then
      cp "$DOTFILES/quickshell/themes/current.json" "$STATE_DIR/current-theme.json"
    fi

    if [ ! -f "$STATE_DIR/theme-preferences.json" ]; then
      printf '%s\n' '{}' > "$STATE_DIR/theme-preferences.json"
    fi

    if [ ! -f "$STATE_DIR/current-wallpaper" ]; then
      printf '%s\n' "$DOTFILES/wallpaper.jpg" > "$STATE_DIR/current-wallpaper"
    fi

    if [ ! -f "$STATE_DIR/wallpaper-index" ]; then
      printf '0\n' > "$STATE_DIR/wallpaper-index"
    fi

    printf '%s\n' '${builtins.toJSON {
      inherit hostname;
      profile = hostMeta.profile or "desktop";
    }}' > "$STATE_DIR/device-profile.json"

    if [ ! -f "$GENERATED_DIR/kitty/colors.conf" ] \
      || [ ! -f "$GENERATED_DIR/hypr/hyprlock.conf" ] \
      || [ ! -f "$GENERATED_DIR/starship/starship.toml" ] \
      || [ ! -f "$GENERATED_DIR/gtk/gtk-3.0/gtk.css" ] \
      || [ ! -f "$GENERATED_DIR/gtk/gtk-3.0/settings.ini" ] \
      || [ ! -f "$GENERATED_DIR/gtk/gtk-4.0/gtk.css" ] \
      || [ ! -f "$GENERATED_DIR/gtk/gtk-4.0/settings.ini" ]; then
      ${pkgs.bash}/bin/bash "$DOTFILES/quickshell/scripts/apply-theme-state.sh" >/dev/null 2>&1 || true
    fi
  '';

  # Tema GTK + ícones (propaga via gsettings pro qt.platformTheme=gnome)
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    gtk4.theme = config.gtk.theme;
    iconTheme = {
      name    = "Colloid-Strata-Dark";
      package = colloidIconTheme;
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

  xdg.desktopEntries.strata-extract-here = {
    name = "Extrair aqui";
    genericName = "Extrator de arquivos";
    exec = "${archiveExtractHere}/bin/strata-extract-here %F";
    terminal = false;
    noDisplay = true;
    icon = "org.gnome.FileRoller";
    categories = [ "Utility" "Archiving" ];
    mimeType = archiveMimeTypes;
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
      "x-scheme-handler/proton-authenticator" = "proton-authenticator-handler.desktop";
    } // builtins.listToAttrs (map (mimeType: {
      name = mimeType;
      value = "strata-extract-here.desktop";
    }) archiveMimeTypes);
  };

  xdg.userDirs = {
    enable = true;
    setSessionVariables = true;
    createDirectories = true;
    desktop = "$HOME/Área de Trabalho";
    documents = "$HOME/Documentos";
    download = "$HOME/Downloads";
    music = "$HOME/Música";
    pictures = "$HOME/Imagens";
    publicShare = "$HOME/Público";
    templates = "$HOME/Modelos";
    videos = "$HOME/Vídeos";
  };

  # Hyprland (monitores vêm do arquivo por host)
  xdg.configFile."hypr/hyprland.conf".source = link "hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source  = link "generated/hypr/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source  = link "hypridle.conf";
  xdg.configFile."hypr/monitors.conf".source  = link "hosts/${hostname}/hyprland-monitors.conf";
  xdg.configFile."hypr/xdph.conf".text = ''
    screencopy {
      # Multi-GPU systems can fail DMA-BUF allocation and break Kooha after ~1s.
      force_shm = true
      max_fps = 60
    }
  '';

  # Shell & terminal
  xdg.configFile."fish/config.fish".source = link "fish/config.fish";
  xdg.configFile."kitty/kitty.conf".source = link "kitty/kitty.conf";
  xdg.configFile."kitty/strata-theme.conf".source = link "generated/kitty/colors.conf";

  # Desktop UI
  xdg.configFile."quickshell".source = link "quickshell";
  xdg.configFile."mako/config".source = link "generated/mako/config";
  xdg.configFile."satty/config.toml".source = link "generated/satty/config.toml";
  xdg.configFile."gtk-3.0/gtk.css" = {
    source = link "generated/gtk/gtk-3.0/gtk.css";
    force = true;
  };
  xdg.configFile."gtk-3.0/settings.ini" = {
    source = link "generated/gtk/gtk-3.0/settings.ini";
    force = true;
  };
  xdg.configFile."gtk-4.0/gtk.css" = {
    source = link "generated/gtk/gtk-4.0/gtk.css";
    force = true;
  };
  xdg.configFile."gtk-4.0/settings.ini" = {
    source = link "generated/gtk/gtk-4.0/settings.ini";
    force = true;
  };

  # Editor
  xdg.configFile."nvim".source = link "nvim";

  # Ferramentas
  xdg.configFile."fastfetch".source = link "fastfetch";

  # Overrides locais para apps Proton:
  # - expõem ícones que os pacotes colocam só em share/pixmaps
  # - registram o callback scheme do Authenticator para o fluxo de login
  home.file.".local/share/applications/proton-pass.desktop".text = ''
    [Desktop Entry]
    Name=Proton Pass
    Comment=Proton Pass desktop application
    GenericName=Password Manager
    Exec=proton-pass %U
    Icon=${pkgs.proton-pass}/share/pixmaps/proton-pass.png
    Type=Application
    StartupNotify=true
    StartupWMClass=proton-pass
    Categories=Utility;
  '';

  home.file.".local/share/applications/proton-mail.desktop".text = ''
    [Desktop Entry]
    Name=Proton Mail
    Comment=Proton official desktop application for Proton Mail and Proton Calendar
    GenericName=Proton Mail
    Exec=proton-mail %U
    Icon=${pkgs.protonmail-desktop}/share/pixmaps/proton-mail.png
    Type=Application
    StartupNotify=true
    StartupWMClass=proton-mail
    Categories=Network;Email;
    MimeType=x-scheme-handler/mailto;
  '';

  home.file.".local/share/applications/Proton Authenticator.desktop".text = ''
    [Desktop Entry]
    Name=Proton Authenticator
    Comment=Proton Authenticator
    Exec=proton-authenticator %U
    Icon=${pkgs.proton-authenticator}/share/icons/hicolor/128x128/apps/proton-authenticator.png
    Type=Application
    Terminal=false
    StartupNotify=true
    StartupWMClass=proton-authenticator
    Categories=Utility;
    MimeType=x-scheme-handler/proton-authenticator;
  '';

  home.file.".local/share/applications/proton-authenticator-handler.desktop".text = ''
    [Desktop Entry]
    Name=Proton Authenticator Handler
    Comment=Callback handler for Proton Authenticator login
    Exec=proton-authenticator %U
    Icon=${pkgs.proton-authenticator}/share/icons/hicolor/128x128/apps/proton-authenticator.png
    Type=Application
    Terminal=false
    NoDisplay=true
    StartupNotify=true
    StartupWMClass=proton-authenticator
    Categories=Utility;
    MimeType=x-scheme-handler/proton-authenticator;
  '';

  # Git e SSH
  home.file.".gitconfig".source    = link "git/config";
  home.file.".ssh/config" = {
    source = link "ssh/config";
    force  = true;
  };
}
