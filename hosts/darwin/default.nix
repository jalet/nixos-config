{
  config,
  pkgs,
  ...
}: let
  user = "jj";
in {
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    ../../modules/shared/cachix
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  # Setup user, packages, programs
  nix = {
    package = pkgs.nixUnstable;
    settings.trusted-users = ["@admin" "${user}"];

    gc = {
      user = "root";
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;

  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs;
    [
    ]
    ++ (import ../../modules/shared/packages.nix {inherit pkgs;});

  # Enable fonts dir
  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      (nerdfonts.override {fonts = ["FiraCode" "Hack"];})
    ];
  };
  #services.gpg-agent.enable = true;
  system = {
    stateVersion = 4;

    defaults = {
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark"; # set dark mode
        ApplePressAndHoldEnabled = false;
        AppleShowAllExtensions = true;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 30;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      dock = {
        autohide = true;
        show-recents = false;
        launchanim = false;
        orientation = "bottom";
        tilesize = 24;
      };

      loginwindow = {
        GuestEnabled = false;
      };

      finder = {
        AppleShowAllExtensions = true;
        FXEnableExtensionChangeWarning = false;
        CreateDesktop = false; # disable desktop icons
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = false;
        Dragging = false;
      };

      spaces = {
        spans-displays = false;
      };
    };

    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToEscape = true;
    };
  };

  services.yabai.enable = true;
  services.yabai.package = pkgs.yabai;
  services.yabai.enableScriptingAddition = true;
  services.yabai.extraConfig = ''
    yabai -m config status_bar                   on
    yabai -m config status_bar_text_font         "Helvetica Neue:Bold:12.0"
    yabai -m config status_bar_icon_font         "FontAwesome:Regular:12.0"
    yabai -m config status_bar_background_color  0xff202020
    yabai -m config status_bar_foreground_color  0xffa8a8a8
    yabai -m config status_bar_space_icon_strip  I II III IV V VI VII VIII IX X
    yabai -m config status_bar_power_icon_strip   
    yabai -m config status_bar_space_icon        
    yabai -m config status_bar_clock_icon        

    yabai -m config mouse_follows_focus          off
    yabai -m config focus_follows_mouse          on
    yabai -m config window_placement             first_child
    yabai -m config window_topmost               off
    yabai -m config window_opacity               off
    yabai -m config window_opacity_duration      0.0
    yabai -m config window_shadow                on
    yabai -m config window_border                off
    yabai -m config window_border_width          4
    yabai -m config active_window_border_color   0xff775759
    yabai -m config normal_window_border_color   0xff505050
    yabai -m config insert_window_border_color   0xffd75f5f
    yabai -m config active_window_opacity        1.0
    yabai -m config normal_window_opacity        0.90
    yabai -m config split_ratio                  0.50
    yabai -m config auto_balance                 off
    yabai -m config mouse_modifier               fn
    yabai -m config mouse_action1                move
    yabai -m config mouse_action2                resize

    yabai -m config layout                       bsp
    yabai -m config top_padding                  10
    yabai -m config bottom_padding               10
    yabai -m config left_padding                 10
    yabai -m config right_padding                10
    yabai -m config window_gap                   10
    yabai -m rule --add app="choose" manage=off
  '';

  services.skhd.enable = true;
  services.skhd.package = pkgs.skhd;
  services.skhd.skhdConfig = ''
    #################################################################################
    # Shortcuts for opening application or run scripts. All using the <leader> + num
    # pad keys.
    #
    # 0x53 == 1
    # 0x54 == 2
    # 0x55 == 3
    # 0x56 == 4
    # 0x57 == 5
    # 0x58 == 6
    # 0x59 == 7
    # 0x5B == 8
    # 0x5C == 9
    #
    #################################################################################

    # focus window
    lctrl - f : yabai -m window --toggle zoom-fullscreen
    lctrl - h : yabai -m window --focus west
    lctrl - j : yabai -m window --focus south
    lctrl - k : yabai -m window --focus north
    lctrl - l : yabai -m window --focus east
    lctrl - 0x1E : yabai -m window --focus next # ]
    lctrl - 0x21 : yabai -m window --focus prev # [

    # swap window
    lctrl + lalt - h : yabai -m window --swap west
    lctrl + lalt - j : yabai -m window --swap south
    lctrl + lalt - k : yabai -m window --swap north
    lctrl + lalt - l : yabai -m window --swap east

    # move window
    lctrl + lalt + shift - h : yabai -m window --warp west
    lctrl + lalt + shift - j : yabai -m window --warp south
    lctrl + lalt + shift - k : yabai -m window --warp north
    lctrl + lalt + shift - l : yabai -m window --warp east

    cmd - 1 : yabai -m space --focus 1
    cmd - 2 : yabai -m space --focus 2
    cmd - 3 : yabai -m space --focus 3
    cmd - 4 : yabai -m space --focus 4
    cmd - 5 : yabai -m space --focus 5
    cmd - 6 : yabai -m space --focus 6
    cmd - 7 : yabai -m space --focus 7
    cmd - 8 : yabai -m space --focus 8
    cmd - 9 : yabai -m space --focus 9

    # Rotate on X and Y axis
    lctrl + lalt - x : yabai -m space --mirror x-axis
    lctrl + lalt - y : yabai -m space --mirror y-axis

    # Rotate window clockwise and counter clockwise
    lctrl + lalt - 0x1E : yabai -m space --rotate 270 # [
    lctrl + lalt - 0x21 : yabai -m space --rotate 90  # ]

    # Equalize size of windows
    lctrl + lalt - 0x31 : yabai -m space --balance # <space>

    # Set insertion point for focused container
    shift + lalt - h : yabai -m window --insert west
    shift + lalt - j : yabai -m window --insert south
    shift + lalt - k : yabai -m window --insert north
    shift + lalt - l : yabai -m window --insert east
  '';
}
