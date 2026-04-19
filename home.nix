{ config, pkgs, lib, username ? "ankh", ... }:
{
  home.enableNixpkgsReleaseCheck = false;
  home.username      = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "25.11";
  programs.home-manager.enable = true;

  xdg.configFile."quickshell".source = config.lib.file.mkOutOfStoreSymlink "/home/${username}/dotfiles/quickshell";
  xdg.configFile."hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/${username}/dotfiles/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/${username}/dotfiles/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/${username}/dotfiles/hypridle.conf";
}
