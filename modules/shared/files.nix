{
  user,
  config,
  pkgs,
  ...
}: let
  Mocha = "Catppuccin Mocha.tmTheme";
  HOME = "${config.users.users.${user}.home}";
in {
  "${HOME}/.config/bat/themes/${Mocha}".text =
    builtins.readFile
    (pkgs.fetchFromGitHub
      {
        owner = "catppuccin";
        repo = "bat";
        rev = "2bafe4454d8db28491e9087ff3a1382c336e7d27";
        sha256 = "sha256-yHt3oIjUnljARaihalcWSNldtaJfVDfmfiecYfbzGs0=";
      }
      + "/themes/${Mocha}");

  "${HOME}/.npmrc".text = ''
    # npmrc
    cache=${HOME}/.cache/npm
    prefix=${HOME}/.local/npm
  '';

  "${HOME}/.markdownlint.yaml".text = ''
    --- 
    default: true
    MD013:
      tables: false
  '';

  "${HOME}/.config/yamllint/config".text = ''
    ---
    yaml-files:
      - '*.yaml'
      - '*.yml'
      - '.yamllint'

    rules:
      anchors: enable
      braces: enable
      brackets: enable
      colons: enable
      commas: enable
      comments:
        level: warning
      comments-indentation:
        level: warning
      document-end: disable
      document-start:
        level: warning
      empty-lines: enable
      empty-values: disable
      float-values: disable
      hyphens: enable
      indentation:
        spaces: consistent
        indent-sequences: consistent
      key-duplicates: enable
      key-ordering: disable
      line-length:
        max: 120
        allow-non-breakable-words: true
        allow-non-breakable-inline-mappings: true
      new-line-at-end-of-file: enable
      new-lines: enable
      octal-values: disable
      quoted-strings: disable
      trailing-spaces: enable
      truthy:
        level: warning
  '';

  "${HOME}/.config/ghostty/config".text = ''
    background-opacity = 0.85
    font-family = "Hack Nerd Font Mono"
    font-size = 16
    theme = Gruvbox Dark
    window-padding-x = 5
  '';

  "${HOME}/.editodconfig".text = ''
    # EditorConfig is awesome: https://EditorConfig.org

    # top-most EditorConfig file
    root = true

    # Unix-style newlines with a newline ending every file
    [*]
    end_of_line = lf
    insert_final_newline = true
    charset = utf-8

    # 4 space indentation
    [*.py]
    indent_style = space
    indent_size = 4

    # Tab indentation (no size specified)
    [Makefile]
    indent_style = tab
  '';

  "${HOME}/.config/git/allowed-signers".text = ''
    j@jarsater.com valid-before="20250124" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP6Za2Rait6hAZYgHkL1oTR5A4mnupddtODneWfqw6JzAAAABnNzaDpwZw== ssh:pg 
    j@jarsater.com valid-before="20250124" sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGe3FuAf6BN0Zr3aUEa/wIQ2S3vQuZ8ihGRqCs2/HiHnAAAABnNzaDptZQ== ssh:me
  '';
}
