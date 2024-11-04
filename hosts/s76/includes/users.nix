{ ... }:
{
  users.users.jalet = {
    isNormalUser = true;
    description = "Joakim Jarsater";
    extraGroups = [ "networkmanager" "wheel" "audio" ];

    openssh = {
      authorizedKeys = {
        keys = [
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIH9bEM4DbK2B5zSnVahMw+RdyHmyokVzGgDRxyh0B6SpAAAABnNzaDptZQ== ssh:me" # YubiKey 5Ci FIPS (me)
          "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGe3FuAf6BN0Zr3aUEa/wIQ2S3vQuZ8ihGRqCs2/HiHnAAAABnNzaDptZQ== ssh:me" # YubiKey 5C (me)
        ];
      };
    };
  };
}
