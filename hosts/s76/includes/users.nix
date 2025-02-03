{ pkgs, ... }:
{
  users.groups.k3s = { };

  users.users.jalet = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "Joakim Jarsater";
    extraGroups = [ "networkmanager" "wheel" "audio" "input" "video" "k3s" ];

    openssh = {
      authorizedKeys = {
        keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH9bEM4DbK2B5zSnVahMw+RdyHmyokVzGgDRxyh0B6SpAAAABnNzaDptZQ== ssh:me" # YubiKey 5Ci FIPS (me)
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGe3FuAf6BN0Zr3aUEa/wIQ2S3vQuZ8ihGRqCs2/HiHnAAAABnNzaDptZQ== ssh:me" # YubiKey 5C (me)
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGiptyR04iPnEFoOG/xYc49QHKQRASh8CupSojnVSD6D cardno:12_763_134" # Yubikey 5C
        ];
      };
    };
  };
}
