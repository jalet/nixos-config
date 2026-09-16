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
        "git"
        "fzf"
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
      export PATH=$PATH:$HOME/go/bin
      export PATH=$PATH:/opt/homebrew/bin

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"

      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)

      # Heavy one-shot setup: only run in the outermost shell, not in every tmux pane.
      # Tmux panes inherit the env set here, so DOCKER_HOST/GPG_TTY survive into them.
      if [[ -z "$TMUX" ]]; then
        gpgconf --launch gpg-agent
        gpg-connect-agent updatestartuptty /bye > /dev/null
        if command -v podman >/dev/null 2>&1; then
          _podman_sock=$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}' 2>/dev/null)
          [[ -n "$_podman_sock" ]] && export DOCKER_HOST="unix://$_podman_sock"
          unset _podman_sock
        fi
      fi

      # AWS CLI uses a callback completer, not a static file
      command -v aws_completer >/dev/null 2>&1 && complete -C aws_completer aws

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
      K9S_CONFIG_DIR = "$HOME/.config/k9s";
    };
  };

  # Several coconut repos carry an .envrc that builds a per-directory
  # .aws/config and .kube/config and exports AWS_CONFIG_FILE and KUBECONFIG
  # scoped to that repo, which is what keeps one customer's console session out
  # of another's. Without direnv those files are inert and every repo shares
  # whatever global AWS context happens to be active.
  #
  # The hook runs on precmd, so it fires per shell rather than per session:
  # each tmux pane opened in a repo by tmux-sessions.nix loads that repo's
  # environment on its own. An .envrc still has to be approved once with
  # `direnv allow`, by design - it is arbitrary shell code from a git repo.
  direnv = {
    enable = true;
    enableZshIntegration = true;

    # Caches the flake devShell in the Nix store and keeps it from being
    # garbage-collected, turning a repeat `cd` into a hash lookup rather than a
    # re-evaluation. Matters for the flake-based repos - homelab-nixos,
    # mcp-fabric, pgoauth, jarvis - where a cold evaluation is slow enough to
    # feel like a hang on every directory change.
    nix-direnv.enable = true;
  };

  bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      theme = "Nord";
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
    # Nord palette (bg=-1 keeps the terminal background transparent)
    defaultOptions = [
      "--color=fg:#D8DEE9,bg:-1,hl:#A3BE8C"
      "--color=fg+:#ECEFF4,bg+:#3B4252,hl+:#A3BE8C"
      "--color=info:#EBCB8B,prompt:#BF616A,pointer:#B48EAD"
      "--color=marker:#A3BE8C,spinner:#B48EAD,header:#5E81AC"
    ];
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
    baseIndex = 1;
    historyLimit = 50000;
    extraConfig = ''
      # Undo tmux-sensible's reattach-to-user-namespace wrapper (legacy pre-Mojave fix)
      set -gu default-command
      setw -g pane-base-index 1
      set -ag terminal-features ',*:RGB'

      set-option -g status-position bottom

      # Nord palette (matches starship exactly)
      # color_fg0    = #ECEFF4 (nord6)
      # color_bg1    = #3B4252 (nord1)
      # color_bg3    = #4C566A (nord3)
      # color_orange = #D08770 (nord12)
      # color_yellow = #EBCB8B (nord13)
      # color_aqua   = #88C0D0 (nord8)
      # color_blue   = #5E81AC (nord10)
      # color_purple = #B48EAD (nord15)

      set -g status-style "bg=default"
      set -g status-left-length 40
      set -g status-right-length 40

      # Rounded powerline separators: U+E0B4 () and U+E0B6 ()
      # Status left: session name in orange pill
      set -g status-left "#[fg=#D08770,bg=default]#[fg=#ECEFF4,bg=#D08770,bold] #S #[fg=#D08770,bg=default] "

      # Status right: empty
      set -g status-right ""
      set -g window-status-separator " "

      # Window base styles control cap colors; inline overrides handle fill only
      set -g window-status-style "fg=#4C566A,bg=default,none"
      set -g window-status-current-style "fg=#EBCB8B,bg=default,bold"

      # Window: inactive — grey pill (caps inherit fg=#4C566A from window-status-style)
      set -g window-status-format "#[fg=#ECEFF4,bg=#4C566A] #I > #W #[default]"

      # Window: active — yellow pill (caps inherit fg=#EBCB8B from window-status-current-style)
      set -g window-status-current-format "#[fg=#2E3440,bg=#EBCB8B] #I > #W #[default]"

      # Pane borders
      set -g pane-border-style "fg=#4C566A"
      set -g pane-active-border-style "fg=#D08770"

      # Message style
      set -g message-style "bg=#EBCB8B,fg=#3B4252"
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
    settings = {
      "*" = {
        SetEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}