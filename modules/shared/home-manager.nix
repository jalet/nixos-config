{
  pkgs,
  lib,
  ...
}: let
  name = "Joakim Jarsäter";
  email = "joakim@jarsater.com";
  signingkey = "0x4EE738F142BF5D51";
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
      export PATH=$PATH:$HOME/.local/bin
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
      man = "batman";
      e = "nvim";
      k = "kubecolor";
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

    settings = {
      alias = {
        st = "status";
        ls = "ls-files";
        co = "checkout";
        cob = "checkout -b";
      };

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
        name = name;
        email = email;
        signingkey = signingkey;
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

    ignores = [
      # -- Compiled source ----------------------------------------------------
      "*.com"
      "*.class"
      "*.dll"
      "*.exe"
      "*.o"
      "*.so"

      # Packages --------------------------------------------------------------
      "*.7z"
      "*.dmg"
      "*.gz"
      "*.iso"
      "*.jar"
      "*.rar"
      "*.tar"
      "*.zip"

      # Logs and databases ----------------------------------------------------
      "*.log"
      "*.sqlite"

      # OS generated files ----------------------------------------------------
      ".DS_Store"
      ".DS_Store?"
      "._*"
      ".Spotlight-V100"
      ".Trashes"
      "ehthumbs.db"
      "Thumbs.db"
      "dump.rdp"
      ".vscode"

      # -- IntelliJ -----------------------------------------------------------
      ".idea/"
      ".idea/aws.xml"
      ".idea/misc.xml"
      ".idea/modules.xml"
      ".idea/payments-atlantis.iml"
      ".idea/vcs.xml"
      ".idea/workspace.xml"

      # -- Misc ---------------------------------------------------------------
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

      # -- Code assistance ----------------------------------------------------
      ".claude/"
    ];
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
      set -g @tmux-gruvbox "dark"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      tmux-fzf
      gruvbox
    ];
  };

  oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromJSON(''{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "blocks": [
    {
      "alignment": "left",
      "segments": [
        {
          "background": "#3A3A3A",
          "foreground": "#ffffff",
          "style": "powerline",
          "template": "{{ if .WSL }}WSL at{{ end }} {{.Icon}} ",
          "type": "os"
        },
        {
          "background": "#458588",
          "foreground": "#282828",
          "powerline_symbol": "\ue0b0",
          "options": {
            "style": "full"
          },
          "style": "powerline",
          "template": " {{ .Path }} ",
          "type": "path"
        },
        {
          "background": "#98971A",
          "background_templates": [
            "{{ if or (.Working.Changed) (.Staging.Changed) }}#FF9248{{ end }}",
            "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#ff4500{{ end }}",
            "{{ if gt .Ahead 0 }}#B388FF{{ end }}",
            "{{ if gt .Behind 0 }}#B388FF{{ end }}"
          ],
          "foreground": "#282828",
          "leading_diamond": "\ue0b6",
          "powerline_symbol": "\ue0b0",
          "options": {
            "branch_template": "{{ trunc 25 .Branch }}",
            "fetch_status": true,
            "branch_icon": "\uE0A0 ",
            "branch_identical_icon": "\u25CF"
          },
          "style": "powerline",
          "template": " {{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }} \uf044 {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }} \uf046 {{ .Staging.String }}{{ end }}{{ if gt .StashCount 0 }} \ueb4b {{ .StashCount }}{{ end }} ",
          "trailing_diamond": "\ue0b4",
          "type": "git"
        },
        {
          "background": "#8ED1F7",
          "foreground": "#111111",
          "powerline_symbol": "\ue0b0",
          "options": {
            "fetch_version": true
          },
          "style": "powerline",
          "template": " \ue626 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "type": "go"
        },
        {
          "background": "#4063D8",
          "foreground": "#111111",
          "powerline_symbol": "\ue0b0",
          "options": {
            "fetch_version": true
          },
          "style": "powerline",
          "template": " \ue624 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "type": "julia"
        },
        {
          "background": "#FFDE57",
          "foreground": "#111111",
          "powerline_symbol": "\ue0b0",
          "options": {
            "display_mode": "files",
            "fetch_virtual_env": false
          },
          "style": "powerline",
          "template": " \ue235 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "type": "python"
        },
        {
          "background": "#AE1401",
          "foreground": "#ffffff",
          "powerline_symbol": "\ue0b0",
          "options": {
            "display_mode": "files",
            "fetch_version": true
          },
          "style": "powerline",
          "template": " \ue791 {{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "type": "ruby"
        },
        {
          "background": "#FEAC19",
          "foreground": "#ffffff",
          "powerline_symbol": "\ue0b0",
          "options": {
            "display_mode": "files",
            "fetch_version": false
          },
          "style": "powerline",
          "template": " \uf0e7{{ if .Error }}{{ .Error }}{{ else }}{{ .Full }}{{ end }} ",
          "type": "azfunc"
        },
        {
          "background_templates": [
            "{{if contains \"default\" .Profile}}#FFA400{{end}}",
            "{{if contains \"jan\" .Profile}}#f1184c{{end}}"
          ],
          "foreground": "#ffffff",
          "powerline_symbol": "\ue0b0",
          "options": {
            "display_default": false
          },
          "style": "powerline",
          "template": " \ue7ad {{ .Profile }}{{ if .Region }}@{{ .Region }}{{ end }} ",
          "type": "aws"
        },
        {
          "background": "#ffff66",
          "foreground": "#111111",
          "powerline_symbol": "\ue0b0",
          "style": "powerline",
          "template": " \uf0ad ",
          "type": "root"
        }
      ],
      "type": "prompt"
    }
  ],
  "console_title_template": "{{ .Folder }}",
  "final_space": true,
  "version": 4
}'');
  };

  ssh = {
    enable = true;
    enableDefaultConfig = true;
    matchBlocks = {
      "*" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
