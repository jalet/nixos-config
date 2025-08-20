{ config, inputs, lib, pkgs, ... }:
let
  userName = "jalet";
  userEmail = "joakim@jarsater.com";
  homeDirectory = "/home/${userName}";

  sharedFiles = import ../shared/files.nix { inherit config pkgs lib homeDirectory inputs; };
  sharedPackages = import ../shared/packages.nix { inherit pkgs; };
  sharedPrograms = import ../shared/programs.nix { inherit pkgs lib userName userEmail; };
in
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home = {
    username = lib.mkDefault userName;
    homeDirectory = lib.mkDefault homeDirectory;
    sessionPath = [
      "$HOME/.local/share/nvim/mason/bin"
    ];

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
}
