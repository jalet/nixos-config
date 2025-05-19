{ pkgs, ... }:
{
  services = {

    k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        "--cluster-init"

        "--node-ip=10.10.99.200"
        "--advertise-address=10.10.99.200"

        "--cluster-cidr=172.16.0.0/16" # Define pod network range
        "--service-cidr=172.17.0.0/16" # Define service network range

        "--disable=flannel"
        "--disable-helm-controller"
        "--disable-kube-proxy"
        "--disable-cloud-controller"
        "--disable-network-policy"
        "--disable=servicelb"
        "--disable=traefik"
        "--flannel-backend=none"
        "--secrets-encryption"
        "--write-kubeconfig-mode=644"
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

    pulseaudio = {
      enable = false;
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
