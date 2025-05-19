{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # Misc
    coreutils
    cryptsetup
    curl
    gcc
    git
    gnumake
    gnupg
    gnupg-pkcs11-scd
    libu2f-host
    neovim
    opensc
    pcsclite
    pcsctools
    pinentry-curses
    pinentry-tty
    python314
    yubikey-personalization

    # k8s
    cilium-cli
    istioctl
    kubernetes-helm
  ];

  environment.shellInit = ''
    gpg-connect-agent /bye
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
    export KUBECONFIG=$HOME/.kube/config
  '';
}
