{ pkgs, lib, userName, userEmail, ... }:
{

  # Let Home Manager install and manage itself.
  home-manager.enable = true;

  gpg = {
    enable = true;

    scdaemonSettings = {
      disable-ccid = true;
    };

    package = pkgs.gnupg.override {
      pcsclite = pkgs.pcsclite.overrideAttrs
        (old: {
          postPatch = old.postPatch + (lib.optionalString (!(lib.strings.hasInfix ''--replace-fail "libpcsclite_real.so.1"'' old.postPatch)) ''
            substituteInPlace src/libredirect.c src/spy/libpcscspy.c \
              --replace-fail "libpcsclite_real.so.1" "$lib/lib/libpcsclite_real.so.1"
          '');
        });
    };
  };


  # Git settings
  git = {
    enable = true;
    userName = userName;
    userEmail = userEmail;
    ignores = [
      # -- Compiled source ----------------------------------------------------------
      "*.com"
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"

      # Packages --------------------------------------------------------------------
      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.jar"
      "*.rar"
      "*.tar"
      "*.zip"

      # Logs and databases ----------------------------------------------------------
      "*.log"
      "*.sqlite"

      # OS generated files ----------------------------------------------------------
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
      "dump.rdp"
      ".vscode"

      # -- IntelliJ -----------------------------------------------------------------
      ".idea/"
      ".idea/aws.xml"
      ".idea/misc.xml"
      ".idea/modules.xml"
      ".idea/payments-atlantis.iml"
      ".idea/vcs.xml"
      ".idea/workspace.xml"

      # -- Misc ---------------------------------------------------------------------
      "config.*-local.yml"
      "*.env"
      "bin/circleci-test-build"
      ".tool-versions"
      ".settings"
      ".classpath"
      ".project"
      ".secrets"
      "spell/"
      ".factorypath"
    ];
    aliases = {
      st = "status";
      ls = "ls-files";
      co = "checkout";
      cob = "checkout -b";
    };
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      pull = {
        rebase = true;
      };
      push = {
        autoSetupRemote = true;
      };
      rebase = {
        autoStash = true;
      };
    };
    signing = {
      key = "0xAB22A52B64CF60D3";
      signByDefault = true;
    };
  };

  tmux = {
    enable = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    clock24 = true;
    baseIndex = 0;
    shell = "$SHELL";
    extraConfig = ''
      set-option -g default-command zsh
      set -ag terminal-overrides ",xterm-256color:RGB"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      yank
      tmux-fzf
      gruvbox
    ];
  };

  bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      theme = "gruvbox-dark";
    };
    extraPackages = builtins.attrValues {
      inherit
        (pkgs.bat-extras)
        batgrep
        batdiff
        batman
        ;
    };
  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "aws"
        "fzf"
        "gh"
        "git"
        "github"
        "kubectl"
        "sudo"
        "terraform"
      ];
    };

    shellAliases = {
      ls = "eza --color=always --icons=always";
      cat = "bat";
      diff = "batdiff";
      rg = "batgrep";
      man = "batman";

      e = "nvim";
    };
  };

  oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON (
      ''{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "background": "#3a3a3a",
          "foreground": "#d65d0e",
          "style": "plain",
          "template": "\u26a1 ",
          "type": "root"
        },
        {
          "background": "transparent",
          "foreground": "#d65d0e",
          "style": "plain",
          "template": "{{ if .WSL }}WSL at {{ end }}{{.Icon}} ",
          "type": "os"
        },
        {
          "background": "#665c54",
          "foreground": "#d5c4a1",
          "leading_diamond": "<transparent,#665c54>\ue0b0</>",
          "properties": {
            "folder_icon": "...",
            "folder_separator_icon": "<transparent> \ue0bd </>",
            "home_icon": "\ueb06",
            "style": "agnoster_short"
          },
          "style": "diamond",
          "template": " {{ .Path }} ",
          "trailing_diamond": "\ue0b0",
          "type": "path"
        },
        {
          "background": "#665c54",
          "background_templates": [
            "{{ if or (.Working.Changed) (.Staging.Changed) }}#d3869b{{ end }}",
            "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#83a598{{ end }}"
          ],
          "foreground": "#d5c4a1",
          "powerline_symbol": "\ue0b0",
          "properties": {
            "fetch_status": true
          },
          "style": "powerline",
          "template": " {{ .HEAD }}{{ if .Staging.Changed }}<#FF6F00> \uf046 {{ .Staging.String }}</>{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ",
          "type": "git"
        },
        {
          "background": "#910000",
          "foreground": "#d5c4a1",
          "powerline_symbol": "\ue0b0",
          "style": "powerline",
          "template": "<transparent> \uf12a</> {{ reason .Code }} ",
          "type": "status"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "segments": [
        {
          "background": "#665c54",
          "foreground": "#d5c4a1",
          "leading_diamond": "\ue0ba",
          "trailing_diamond": "\ue0bc",
          "style": "diamond",
          "template": "  {{ .UserName }}<transparent> / </>{{ .HostName }} ",
          "type": "session"
        },
        {
          "background": "transparent",
          "foreground": "#d65d0e",
          "properties": {
            "time_format": "15:04:05"
          },
          "leading_diamond": "\ue0ba",
          "style": "diamond",
          "template": " {{ .CurrentDate | date .Format }} ",
          "type": "time"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "#d5c4a1",
          "foreground_templates": [
            "{{ if gt .Code 0 }}#ff0000{{ end }}"
          ],
          "properties": {
            "always_enabled": true
          },
          "style": "plain",
          "template": "\u276f ",
          "type": "status"
        }
      ],
      "type": "prompt"
    }
  ],
  "console_title_template": "{{if .Root}} \u26a1 {{end}}{{.Folder | replace \"~\" \"🏚\" }} @ {{.HostName}}",
  "version": 3
}''
    );
  };
}
