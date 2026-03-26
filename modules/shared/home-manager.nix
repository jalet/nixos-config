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

      # Granted assume alias
      alias assume="source ${pkgs.granted}/bin/assume"
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
      set -g @tmux-gruvbox "dark256"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      yank
      tmux-fzf
      gruvbox
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
