{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    coreutils
    curl
    gcc
    git
    gnumake
    neovim
  ];
}
