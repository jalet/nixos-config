{ lib, outputs, ... }:
{
  nixpkgs = {
    config = {
      allowUnfree = true;
    };

    hostPlatform = lib.mkDefault "x86_64-linux";

    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];
  };
}
