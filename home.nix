{ config, pkgs, ... }:

{
  home.username      = "ankh";
  home.homeDirectory = "/home/ankh";
  home.stateVersion  = "25.11";

  programs.home-manager.enable = true;

  # Wallpaper temporário até termos o matugen
  # Baixa qualquer imagem e coloca em ~/wallpaper.jpg antes de rodar
  stylix = {
    enable   = true;
    image    = ./wallpaper.jpg;
    polarity = "dark";

    # Fundos fixos, só acento varia
    override = {
      base00 = "0d0d0f";
      base01 = "111113";
      base02 = "161618";
      base03 = "2a2a2e";
      base04 = "555555";
      base05 = "cecece";
      base06 = "e0e0e0";
      base07 = "f5f5f5";
    };

    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name    = "JetBrainsMono Nerd Font";
      };
      sansSerif = {
        package = pkgs.inter;
        name    = "Inter";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name    = "Noto Color Emoji";
      };
      sizes = {
        terminal     = 13;
        applications = 11;
      };
    };
  };
}
