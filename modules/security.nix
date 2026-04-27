{ username ? "ankh", ... }: {
  security.sudo.extraRules = [
    {
      users = [ "${username}" ];
      commands = [
        { command = "/run/current-system/sw/bin/tee /etc/chromium/policies/managed/strata.json"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/mkdir";  options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/cp";     options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/sed";    options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/tee /var/lib/strata/theme.conf"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/impala"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/strata-bluetooth-toggle"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
