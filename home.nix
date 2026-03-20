{ config, pkgs, ... }:

{
  home.username      = "ankh";
  home.homeDirectory = "/home/ankh";
  home.stateVersion  = "25.11";

  programs.home-manager.enable = true;
}
