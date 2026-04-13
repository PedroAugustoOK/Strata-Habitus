{ config, pkgs, ... }:
{
  home.username      = "ankh";
  home.homeDirectory = "/home/ankh";
  home.stateVersion  = "25.11";
  programs.home-manager.enable = true;

  xdg.configFile."quickshell".source = config.lib.file.mkOutOfStoreSymlink "/home/ankh/dotfiles/quickshell";
  xdg.configFile."hypr/hyprland.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/ankh/dotfiles/hyprland.conf";
  xdg.configFile."hypr/hyprlock.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/ankh/dotfiles/hyprlock.conf";
  xdg.configFile."hypr/hypridle.conf".source = config.lib.file.mkOutOfStoreSymlink "/home/ankh/dotfiles/hypridle.conf";
}
