{ pkgs, ... }:
{
  services = {
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
        theme = "catppuccin-mocha";
        wayland = {
          enable = true;
        };
      };
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
