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

    initContent = lib.mkBefore (''
      # Add local completions directory to fpath
      mkdir -p "$HOME/.zsh/completions"
      fpath=("$HOME/.zsh/completions" $fpath)

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

      # Granted assume alias
      alias assume="source ${pkgs.granted}/bin/assume"
    '' + lib.optionalString pkgs.stdenv.isDarwin ''

      totp() {
        local account
        account=$(ykman oath accounts list | fzf) || return
        ykman oath accounts code -s "$account" | tr -d '\n' | pbcopy
        echo "copied TOTP for: $account"
      }
    '');

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

    signing.format = "openpgp";

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

      url = {
        "ssh://git@github.com/" = {
          insteadOf = ["https://github.com/" "https://git::@github.com/"];
        };
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
      set-option -g status-position bottom
      set -ag terminal-overrides ",xterm-256color:RGB"

      # Gruvbox dark palette (matches starship exactly)
      # color_fg0    = #fbf1c7
      # color_bg1    = #3c3836
      # color_bg3    = #665c54
      # color_orange = #d65d0e
      # color_yellow = #d79921
      # color_aqua   = #689d6a
      # color_blue   = #458588
      # color_purple = #b16286

      set -g status-style "bg=default"
      set -g status-left-length 40
      set -g status-right-length 40

      # Rounded powerline separators: U+E0B4 () and U+E0B6 ()
      # Status left: session name in orange pill
      set -g status-left "#[fg=#d65d0e,bg=default]#[fg=#fbf1c7,bg=#d65d0e,bold] #S #[fg=#d65d0e,bg=default] "

      # Status right: empty
      set -g status-right ""
      set -g window-status-separator " "

      # Window base styles control cap colors; inline overrides handle fill only
      set -g window-status-style "fg=#504945,bg=default,none"
      set -g window-status-current-style "fg=#d79921,bg=default,bold"

      # Window: inactive — grey pill (caps inherit fg=#504945 from window-status-style)
      set -g window-status-format "#[fg=#fbf1c7,bg=#504945] #I > #W #[default]"

      # Window: active — yellow pill (caps inherit fg=#d79921 from window-status-current-style)
      set -g window-status-current-format "#[fg=#1d2021,bg=#d79921] #I > #W #[default]"

      # Pane borders
      set -g pane-border-style "fg=#665c54"
      set -g pane-active-border-style "fg=#d65d0e"

      # Message style
      set -g message-style "bg=#d79921,fg=#3c3836"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      tmux-fzf
    ];
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
  };

  ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}