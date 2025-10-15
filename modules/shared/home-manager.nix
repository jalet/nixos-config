{
  pkgs,
  lib,
  ...
}: let
  name = "Joakim Jarsäter";
  email = "joakim@jarsater.com";
in {
  # Shared shell configuration
  zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "sudo"
        "tmux"
        "aws"
        "fzf"
        "gh"
        "git"
        "github"
        "docker"
        "podman"
        "terraform"

        # kubernetes
        "kubectl"
        "kubectx"
        "helm"
        "argocd"
      ];
    };

    initContent = lib.mkBefore ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Define variables for directories
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH=$PATH:$HOME/.local/npm/bin
      export PATH=$PATH:$HOME/.cargo/bin
      export PATH=$PATH:$(go env GOPATH)/bin
      export PATH=$PATH:/opt/homebrew/bin

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"

      export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')


      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent
      gpg-connect-agent updatestartuptty /bye > /dev/null
    '';

    shellAliases = {
      ls = "eza --color=always --icons=always";
      cat = "bat";
      diff = "batdiff";
      rg = "batgrep";
      man = "batman";

      e = "nvim";
    };

    sessionVariables = {
      EDITOR = "nvim";
      KUBE_EDITOR = "nvim";
    };
  };

  bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
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

  git = {
    enable = true;
    userName = name;
    userEmail = email;

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
        autoSetupRemote = true;
      };

      push = {
        autoSetupRemote = true;
      };

      rebase = {
        autoStash = true;
      };

      commit = {
        gpgsign = true;
      };

      tag = {
        gpgSign = true;
      };

      user = {
        signingkey = "0x4EE738F142BF5D51";
      };

      gpg = {
        ssh = {
          allowedSignersFile = "~/.config/git/allowed-signers";
        };
      };

      log = {
        dateOrder = true;
        graph = true;
      };
    };
  };

  gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      editor = "nvim";
    };
  };

  gpg = {
    enable = false;
    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  tmux = {
    enable = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    clock24 = true;
    baseIndex = 0;
    shell = "$SHELL";
    historyLimit = 10000;
    extraConfig = ''
      set-option -g default-command zsh
      set-option -g status-position top
      set -ag terminal-overrides ",xterm-256color:RGB"
      set -g @tokyo-night-tmux_theme storm
      set -g @tokyo-night-tmux_transparent 0
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      tmux-fzf
      tokyo-night-tmux
    ];
  };

  oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON(''{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "console_title_template": " {{ .Folder }} :: {{if .Root}}Admin{{end}}",
  "palette": {
    "main-bg": "#24283b",
    "terminal-red": "#f7768e",
    "pistachio-green": "#9ece6a",
    "terminal-green": "#73daca",
    "terminal-yellow": "#e0af68",
    "terminal-blue": "#7aa2f7",
    "celeste-blue": "#b4f9f8",
    "light-sky-blue": "#7dcfff",
    "terminal-white": "#c0caf5",
    "white-blue": "#a9b1d6",
    "blue-bell": "#9aa5ce",
    "pastal-grey": "#cfc9c2",
    "terminal-magenta": "#bb9af7",
    "blue-black": "#565f89",
    "terminal-black": "#414868",
    "t-background": "p:main-bg"
  },
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "type": "text",
          "style": "plain",
          "background": "transparent",
          "foreground": "p:terminal-blue",
          "template": "\u279c "
        },
        {
          "type": "path",
          "style": "plain",
          "foreground": "p:terminal-magenta",
          "properties": {
            "style": "folder"
          },
          "template": "<b>{{ .Path }}</b> <p:light-sky-blue>\u26a1</>"
        },
        {
          "type": "git",
          "style": "plain",
          "foreground": "p:light-sky-blue",
          "foreground_templates": [
            "{{ if or (.Working.Changed) (.Staging.Changed) }}p:terminal-red{{ end }}",
            "{{ if and (gt .Ahead 0) (gt .Behind 0)}}p:light-sky-blue {{ end }}",
            "{{ if gt .Ahead 0 }}p:terminal-blue{{ end }}",
            "{{ if gt .Behind 0 }}p:celeste-blue{{ end }}"
          ],
          "template": "({{ .HEAD}})",
          "properties": {
            "fetch_status": true,
            "branch_icon": "\ue725 "
          }
        },
        {
          "type": "status",
          "style": "plain",
          "foreground": "p:terminal-red",
          "template": " \uf00d"
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "right",
      "overflow": "hide",
      "segments": [
        {
          "type": "node",
          "style": "plain",
          "foreground": "p:pistachio-green",
          "template": "\ue718 {{ .Full }} "
        },
        {
          "type": "php",
          "style": "plain",
          "foreground": "p:terminal-blue",
          "template": "\ue73d {{ .Full }} "
        },
        {
          "type": "python",
          "style": "plain",
          "foreground": "p:terminal-yellow",
          "template": "\uE235 {{ .Full }}"
        },
        {
          "type": "julia",
          "style": "plain",
          "foreground": "p:terminal-magenta",
          "template": "\uE624 {{ .Full }}"
        },
        {
          "type": "ruby",
          "style": "plain",
          "foreground": "p:terminal-red",
          "template": "\uE791 {{ .Full}}"
        },
        {
          "type": "go",
          "style": "plain",
          "foreground": "p:light-sky-blue",
          "template": "\uFCD1 {{ .Full}}"
        },
        {
          "type": "command",
          "style": "plain",
          "foreground": "p:white-blue",
          "properties": {
            "command": "git log --pretty=format:%cr -1 || date +%H:%M:%S",
            "shell": "bash"
          }
        }
      ],
      "type": "prompt"
    },
    {
      "alignment": "left",
      "newline": true,
      "segments": [
        {
          "foreground": "p:pistachio-green",
          "style": "plain",
          "template": "\u25b6",
          "type": "text"
        }
      ],
      "type": "prompt"
    }
  ],
  "secondary_prompt": {
    "background": "transparent",
    "foreground": "p:terminal-blue",
    "template": "\u279c "
  },
  "transient_prompt": {
    "background": "p:t-background",
    "foreground": "p:terminal-blue",
    "template": "\u279c "
  },
  "final_space": true,
  "version": 3,
  "terminal_background": "p:t-background"
}'');
  };

  ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
