{ config, lib, ... }:
{
  networking = {
    enableIPv6 = false;

    hostName = "s76";
    useDHCP = lib.mkDefault true;

    networkmanager = {
      enable = true;

      wifi = {
        powersave = false;
      };
    };

    firewall = {
      enable = false;
      checkReversePath = "loose";

      trustedInterfaces = [
        "cilium_*"
        "lxc*"
      ];
    };
  };
}
