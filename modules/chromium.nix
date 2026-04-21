{ ... }: {
  # Garante que /etc/chromium/policies/managed/ exista como diretório regular
  # para que set-theme.sh possa escrever strata.json via sudo tee (NOPASSWD
  # liberado em modules/security.nix).
  environment.etc."chromium/policies/managed/.keep".text = "";
}
