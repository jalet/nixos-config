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
    theme = nord
    window-padding-x = 5
  '';

  # k9s config (XDG; k9s pointed here via K9S_CONFIG_DIR in shared/home-manager.nix).
  # views.yaml adds a WORKLOAD column from the Karpenter workload-type node label.
  "${HOME}/.config/k9s/views.yaml".source = ./config/k9s/views.yaml;
  "${HOME}/.config/k9s/aliases.yaml".source = ./config/k9s/aliases.yaml;
  "${HOME}/.config/k9s/config.yaml".source = ./config/k9s/config.yaml;
  "${HOME}/.config/k9s/skins/nord.yaml".source = ./config/k9s/skins/nord.yaml;
}
