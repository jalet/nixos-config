{ lib, ... }:
{
  networking = {
    hostName = "s76";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true;
  };
}
