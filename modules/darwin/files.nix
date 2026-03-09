{
  user,
  config,
  pkgs,
  ...
}: let
  HOME = "${config.users.users.${user}.home}";
in {
  "${HOME}/.hushlogin".text = ""; # Hide login message

  "${HOME}/.gnupg/gpg-agent.conf".text = ''
    pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
    enable-ssh-support
    default-cache-ttl 7200
    max-cache-ttl 7200
    default-cache-ttl-ssh 86400
    max-cache-ttl-ssh 86400
    ttyname $GPG_TTY
  '';

  "${HOME}/.config/ghostty/config".text = ''
    font-family = Hack Nerd Font Mono
    font-size = 16
    theme = Gruvbox Dark
    background-opacity = 0.95
    window-padding-x = 5
  '';
}
