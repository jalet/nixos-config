{ pkgs, ... }:
{
  services = {

    k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        # For kubectl management
        "--tls-san=v20.home.local"
        "--write-kubeconfig-mode=640"
        "--write-kubeconfig-group=k3s"

        # disable stuff
        "--disable=traefik"

        # Use Cilium instead
        "--disable-network-policy"
        "--flannel-backend=none"
      ];
    };

    pcscd = {
      enable = true;
    };

    openssh = {
      enable = true;
      allowSFTP = false;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        UsePAM = false;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    displayManager = {
      sddm = {
        package = pkgs.kdePackages.sddm;
        enable = true;
        wayland = {
          enable = true;
        };
      };
    };

    udev = {
      packages = with pkgs; [ yubikey-personalization ];
    };

    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
  };
}
