{ ... }: {
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    General.EnableNetworkConfiguration = true;
    Network.EnableIPv6 = true;
  };
}
