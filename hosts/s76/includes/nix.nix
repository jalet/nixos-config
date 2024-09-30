{ lib, inputs, ... }:
{
  nix = {
    nixPath = [ "nixos-config=/home/jalet/.local/share/src/nixcfg:/etc/nixos" ];
    settings = {
      experimental-features = "nix-command flakes";
      allowed-users = [ "jalet" ];
      trusted-users = [
        "root"
        "jalet"
      ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    registry =
      (lib.mapAttrs (_: flake: { inherit flake; }))
        ((lib.filterAttrs (_: lib.isType "flake")) inputs);
  };
}
