{ pkgs, ... }:

let
  strata-sddm-theme = pkgs.stdenv.mkDerivation {
    pname = "sddm-theme-strata";
    version = "1.0";
    src = ./sddm-theme;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/sddm/themes/strata
      cp Main.qml metadata.desktop theme.conf $out/share/sddm/themes/strata/
      cp ${../wallpaper.jpg} $out/share/sddm/themes/strata/background.jpg
    '';
  };
in
{
  services.greetd.enable = false;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "strata";
    extraPackages = with pkgs.kdePackages; [
      qt5compat
    ];
  };

  environment.systemPackages = [
    strata-sddm-theme
  ];
}
