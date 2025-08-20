{ pkgs, ... }:
let
  fixMountPatch = pkgs.fetchpatch {
    url = "https://github.com/NixOS/nixpkgs/pull/405952.patch";
    sha256 = "sha256-tLdKmm0y1fWDlPjNSHTLHExBOgZtodunVO6cPh3JKx0=";
  };

  myUtilLinuxMinimal = pkgs.util-linuxMinimal.overrideAttrs (prev: {
    patches = (prev.patches or [ ]) ++ [ fixMountPatch ];
  });

  myK3s = pkgs.k3s.override {
    util-linux = myUtilLinuxMinimal;
  };
in
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

        "--prefer-bundled-bin"
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
