{ config, pkgs, lib, username ? "ankh", ... }:
let
  dotfiles = "/home/${username}/dotfiles";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${path}";
in {
  home.enableNixpkgsReleaseCheck = false;
  home.username      = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "25.11";
  programs.home-manager.enable = true;

  # Hyprland
  xdg.configFile."hypr/hyprland.conf".source = link "hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source  = link "hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source  = link "hypridle.conf";

  # Shell & terminal
  xdg.configFile."fish/config.fish".source = link "fish/config.fish";
  xdg.configFile."kitty/kitty.conf".source = link "kitty/kitty.conf";
  xdg.configFile."kitty/colors.conf".source = link "kitty/colors.conf";

  # Desktop UI
  xdg.configFile."quickshell".source = link "quickshell";
  xdg.configFile."mako/config".source = link "mako/config";

  # Editor
  xdg.configFile."nvim".source = link "nvim";

  # Ferramentas
  xdg.configFile."fastfetch".source = link "fastfetch";
}
