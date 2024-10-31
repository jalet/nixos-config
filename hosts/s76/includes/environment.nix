{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    gcc
    git
    gnumake
    neovim
    hypridle
    hyprpaper
    hyprlock
    (catppuccin-sddm.override {
      flavor = "mocha";
      font = "Fira Code Nerd Font Mono";
      fontSize = "12";
      background = "${../../../wallpapers/wallhaven-sxzm3l.png}";
      loginBackground = true;
    })
  ];
}
