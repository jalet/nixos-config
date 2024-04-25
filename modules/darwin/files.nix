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

  "${HOME}/.hushlogin".text = ""; # Hide login message

  # https://github.com/felixkratz/sketchybar/discussions/12?sort=top#discussioncomment-4623255
  "${HOME}/.config/sketchybar/plugins/disk.sh".text = ''
    #!/usr/bin/env bash
    #disk.sh

    sketchybar -m --set "$NAME" label="$(df -H | grep -E '^(/dev/disk3s5).' | awk '{ printf ("%s\n", $5) }')"
  '';

  # https://github.com/FelixKratz/SketchyBar/discussions/12?sort=top#discussioncomment-4623255
  "${HOME}/.config/sketchybar/plugins/network.sh".text = ''
    #!/usr/bin/env bash

    UPDOWN=$(ifstat -i "en0" -b 0.1 1 | tail -n1)
    DOWN=$(echo "$UPDOWN" | awk "{ print \$1 }" | cut -f1 -d ".")
    UP=$(echo "$UPDOWN" | awk "{ print \$2 }" | cut -f1 -d ".")

    DOWN_FORMAT=""
    if [ "$DOWN" -gt "999" ]; then
    	DOWN_FORMAT=$(echo "$DOWN" | awk '{ printf "%03.0f Mbps", $1 / 1000}')
    else
    	DOWN_FORMAT=$(echo "$DOWN" | awk '{ printf "%03.0f kbps", $1}')
    fi

    UP_FORMAT=""
    if [ "$UP" -gt "999" ]; then
    	UP_FORMAT=$(echo "$UP" | awk '{ printf "%03.0f Mbps", $1 / 1000}')
    else
    	UP_FORMAT=$(echo "$UP" | awk '{ printf "%03.0f kbps", $1}')
    fi

    sketchybar -m --set network.down label="$DOWN_FORMAT" icon.highlight=$(if [ "$DOWN" -gt "0" ]; then echo "on"; else echo "off"; fi) \
    	--set network.up label="$UP_FORMAT" icon.highlight=$(if [ "$UP" -gt "0" ]; then echo "on"; else echo "off"; fi)
  '';

  # https://github.com/FelixKratz/SketchyBar/discussions/12?sort=top#discussioncomment-4623255
  "${HOME}/.config/sketchybar/plugins/icons.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash

      export BATTERY=
      export CPU=
      export DISK=
      export MEMORY=﬙
      export NETWORK=
      export NETWORK_DOWN=
      export NETWORK_UP=
    '';
  };

  # https://github.com/FelixKratz/SketchyBar/discussions/12?sort=top#discussioncomment-4623255
  "${HOME}/.config/sketchybar/plugins/colors.sh" = {
    executable = true;
    text = ''
      !/usr/bin/env bash

      #
      #
      # Catppuccin Macchiato palette
      #
      #

      export BASE=0xff24273a
      export MANTLE=0xff1e2030
      export CRUST=0xff181926

      export TEXT=0xffcad3f5
      export SUBTEXT0=0xffb8c0e0
      export SUBTEXT1=0xffa5adcb

      export SURFACE0=0xff363a4f
      export SURFACE1=0xff494d64
      export SURFACE2=0xff5b6078

      export OVERLAY0=0xff6e738d
      export OVERLAY1=0xff8087a2
      export OVERLAY2=0xff939ab7

      export BLUE=0xff8aadf4
      export LAVENDER=0xffb7bdf8
      export SAPPHIRE=0xff7dc4e4
      export SKY=0xff91d7e3
      export TEAL=0xff8bd5ca
      export GREEN=0xffa6da95
      export YELLOW=0xffeed49f
      export PEACH=0xfff5a97f
      export MAROON=0xffee99a0
      export RED=0xffed8796
      export MAUVE=0xffc6a0f6
      export PINK=0xfff5bde6
      export FLAMINGO=0xfff0c6c6
      export ROSEWATER=0xfff4dbd6

      export RANDOM_CAT_COLOR=("$BLUE" "$LAVENDER" "$SAPPHIRE" "$SKY" "$TEAL" "$GREEN" "$YELLOW" "$PEACH" "$MAROON" "$RED" "$MAUVE" "$PINK" "$FLAMINGO" "$ROSEWATER")

      function getRandomCatColor() {
        echo "''${RANDOM_CAT_COLOR[ $RANDOM % ''${#RANDOM_CAT_COLOR[@]} ]}"
      }

      #
      # LEGACY COLORS
      #
      # Color Palette
      export GREY=0xff939ab7
      export TRANSPARENT=0x00000000

      # General bar colors
      export BAR_COLOR=$BASE
      export ICON_COLOR=$TEXT # Color of all icons
      export LABEL_COLOR=$TEXT # Color of all labels
    '';
  };

  "${HOME}/.config/sketchybar/plugins/battery.sh" = {
    executable = true;
    text =
      pkgs.fetchFromGitHub
      {
        owner = "FelixKratz";
        repo = "SketchyBar";
        rev = "c6b8aa8288e4895f0d7764fb28376ef90cc00740";
        sha256 = "sha256-oP/1It82EfbN2yNEtrh9nMSa9RA7nRarn8dbQnO3Spg=";
      }
      + /plugins/battery.sh;
  };

  "${HOME}/.config/sketchybar/plugins/space.sh" = {
    executable = true;
    text =
      pkgs.fetchFromGitHub
      {
        owner = "FelixKratz";
        repo = "SketchyBar";
        rev = "c6b8aa8288e4895f0d7764fb28376ef90cc00740";
        sha256 = "sha256-oP/1It82EfbN2yNEtrh9nMSa9RA7nRarn8dbQnO3Spg=";
      }
      + /plugins/space.sh;
  };

  "${HOME}/.config/sketchybar/plugins/volume.sh" = {
    executable = true;
    text =
      pkgs.fetchFromGitHub
      {
        owner = "FelixKratz";
        repo = "SketchyBar";
        rev = "c6b8aa8288e4895f0d7764fb28376ef90cc00740";
        sha256 = "sha256-oP/1It82EfbN2yNEtrh9nMSa9RA7nRarn8dbQnO3Spg=";
      }
      + /plugins/volume.sh;
  };

  "${HOME}/.config/sketchybar/plugins/front_app.sh" = {
    executable = true;
    text =
      pkgs.fetchFromGitHub
      {
        owner = "FelixKratz";
        repo = "SketchyBar";
        rev = "c6b8aa8288e4895f0d7764fb28376ef90cc00740";
        sha256 = "sha256-oP/1It82EfbN2yNEtrh9nMSa9RA7nRarn8dbQnO3Spg=";
      }
      + /plugins/front_app.sh;
  };

  "${HOME}/.config/sketchybar/plugins/clock.sh" = {
    executable = true;
    text =
      pkgs.fetchFromGitHub
      {
        owner = "FelixKratz";
        repo = "SketchyBar";
        rev = "c6b8aa8288e4895f0d7764fb28376ef90cc00740";
        sha256 = "sha256-oP/1It82EfbN2yNEtrh9nMSa9RA7nRarn8dbQnO3Spg=";
      }
      + /plugins/clock.sh;
  };
}
