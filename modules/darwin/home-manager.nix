{
  config,
  pkgs,
  lib,
  home-manager,
  ...
}: let
  user = "jj";
  # Define the content of your file as a derivation
  sharedFiles = import ../shared/files.nix {inherit config pkgs user;};
  additionalFiles = import ./files.nix {inherit user config pkgs;};
in {
  imports = [
    ./dock
  ];

  # It me
  users.users.${user} = {
    name = "${user}";
    home = "/Users/${user}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  homebrew = {
    enable = true;
    casks = pkgs.callPackage ./casks.nix {};

    masApps = {
      "Microsoft Outlook" = 985367838;
      "Slack for desktop" = 803453959;
      "OneDrive" = 823766827; 
    };
  };

  # Enable home-manager
  home-manager = {
    useGlobalPkgs = true;
    users.${user} = {
      pkgs,
      config,
      lib,
      ...
    }: {
      home = {
        enableNixpkgsReleaseCheck = false;
        packages = pkgs.callPackage ./packages.nix {};
        file = lib.mkMerge [
          sharedFiles
          additionalFiles
        ];
        stateVersion = "23.11";
      };
      programs = {} // import ../shared/home-manager.nix {inherit config pkgs lib;};

      # Marked broken Oct 20, 2022 check later to remove this
      # https://github.com/nix-community/home-manager/issues/3344
      manual.manpages.enable = true;
    };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock.enable = true;
  local.dock.entries = [
    {path = "/Applications/Slack.app/";}
    {path = "/System/Applications/Messages.app/";}
    {path = "${pkgs.alacritty}/Applications/Alacritty.app/";}
    {path = "${pkgs.kitty}/Applications/Kitty.app/";}
    {path = "/Applications/Microsoft Outlook.app/";}
    {path = "/Applications/Brave Browser.app/";}
    {path = "/Applications/Spotify.app/";}
  ];
}
