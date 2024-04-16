{
  user,
  config,
  pkgs,
  ...
}: let
  HOME = "${config.users.users.${user}.home}";
in {
  "${HOME}/.gnupg/gpg-agent.conf".text = ''
    # https://github.com/drduh/config/blob/master/gpg-agent.conf
    # https://www.gnupg.org/documentation/manuals/gnupg/Agent-Options.html
    pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
    enable-ssh-support
    ttyname $GPG_TTY
    default-cache-ttl 60
    max-cache-ttl 120
  '';
}
