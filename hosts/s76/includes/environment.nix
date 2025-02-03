{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Misc
    cilium-cli
    coreutils
    cryptsetup
    curl
    gcc
    git
    gnumake
    gnupg
    gnupg-pkcs11-scd
    hyprlock
    hyprpaper
    libu2f-host
    neovim
    opensc
    pcsclite
    pcsctools
    pinentry-curses
    pinentry-tty
    yubikey-personalization
  ];

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';
}
