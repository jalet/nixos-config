{ catppucin, config, inputs, lib, pkgs, ... }:
let
  userName = "jalet";
  userEmail = "joakim@jarsater.com";
  homeDirectory = "/home/${userName}";

  sharedFiles = import ../shared/files.nix { inherit config pkgs lib homeDirectory inputs; };
  sharedPackages = import ../shared/packages.nix { inherit pkgs; };
  sharedPrograms = import ../shared/programs.nix { inherit pkgs userName userEmail; };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = lib.mkDefault userName;
    homeDirectory = lib.mkDefault homeDirectory;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    stateVersion = "24.05"; # Please read the comment before changing.

    # The packages option allows you to install Nix packages into your
    # environment.
    packages = sharedPackages ++ pkgs.callPackage ./packages.nix { };

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'file'.
    file = lib.mkMerge [
      sharedFiles
    ] // import ./files.nix { inherit config pkgs lib homeDirectory; };

    sessionVariables = {
      EDITOR = "nvim";
    };
  };

  programs = lib.recursiveUpdate sharedPrograms (import ./programs.nix { inherit pkgs userName userEmail; });


  catppuccin = {
    enable = true;
    flavor = "mocha";
  };

  gtk = {
    enable = true;
    catppuccin = {
      enable = true;
    };
  };

  services = {
    gpg-agent = {
      enable = true;
      defaultCacheTtl = 60;
      defaultCacheTtlSsh = 60;
      maxCacheTtl = 180;
      maxCacheTtlSsh = 180;
      enableSshSupport = true;
      enableScDaemon = true;
      enableZshIntegration = true;
    };

    hyprpaper = {
      enable = true;
      package = pkgs.hyprpaper;
      settings = {
        preload = [
          "${homeDirectory}/nixcfg/wallpapers/lonely-fish.png"
          "${homeDirectory}/nixcfg/wallpapers/wallhaven-sxzm3l.png"
        ];

        wallpaper = [
          "HDMI-A-1, ${homeDirectory}/nixcfg/wallpapers/wallhaven-sxzm3l.png"
        ];
      };
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      xwayland.force_zero_scaling = true;

      exec-once = [
        "waybar"
      ];

      env = [
        "WLR_NO_HARDWARE_CURSORS,1"
      ];

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;

        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "borderangle, 1, 8, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      master = { };

      misc = {
        force_default_wallpaper = -1;
        disable_hyprland_logo = true;
      };

      gestures = {
        workspace_swipe = false;
      };

      input = {
        kb_layout = "us";
        kb_variant = "";
        kb_model = "";
        kb_options = "";
        kb_rules = "";

        follow_mouse = 1;

        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

        touchpad = {
          natural_scroll = true;
        };
      };

      device = {
        name = "epic-mouse-v1";
        sensitivity = -0.5;
      };

      # See https://wiki.hyprland.org/Configuring/Keywords/
      "$mainMod" = "SUPER"; # Sets "Windows" key as main modifier
      "$terminal" = "kitty";
      "$fileManager" = "dolphin";
      "$menu" = "wofi --show drun";

      bind = [
        # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
        "$mainMod, Q, exec, $terminal"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, E, exec, $fileManager"
        "$mainMod, V, togglefloating,"
        "$mainMod, R, exec, $menu"
        "$mainMod, P, pseudo, # dwindle"
        "$mainMod, J, togglesplit, # dwindle"

        # Move focus with mainMod + arrow keys
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Switch workspaces with mainMod + [0-9]
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Move active window to a workspace with mainMod + SHIFT + [0-9]
        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"

        # Example special workspace (scratchpad)
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"

        # Scroll through existing workspaces with mainMod + scroll
        "$mainMod, mouse_down, workspace, e+1"
        "$mainMod, mouse_up, workspace, e-1"
      ];

      bindm = [
        # Move/resize windows with mainMod + LMB/RMB and dragging
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];
    };

    extraConfig = ''
      # See https://wiki.hyprland.org/Configuring/Monitors/
      monitor=,preferred,auto,auto
      
      
      ###################
      ### MY PROGRAMS ###
      ###################
      
      # See https://wiki.hyprland.org/Configuring/Keywords/
      
      # Set programs that you use
    '';
  };
}
