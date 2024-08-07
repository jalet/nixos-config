{
  pkgs,
  ...
}: let
  name = "Joakim Jarsäter";
  user = "jj";
  email = "j@jarsater.com";
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
        "git"
        "terraform"
        "sudo"
      ];
    };

    initExtraFirst = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Define variables for directories
      export PATH=$HOME/.local/share/bin:$PATH

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"


      # nix shortcuts
      shell() {
          nix-shell '<nixpkgs>' -A "$1"
      }

      export GPG_TTY="$(tty)"
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
      gpgconf --launch gpg-agent

      # Podman
      export DOCKER_HOST='unix:///Users/${user}/.local/share/containers/podman/machine/qemu/podman.sock'
    '';

    shellAliases = {
      ls = "eza";
      cat = "bat";
      diff = "batdiff";
      rg = "batgrep";
      man = "batman";

      e = "nvim";
    };
  };

  bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
      theme = "Catppuccin Mocha";
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
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        autocrlf = "input";
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
    };
    signing = {
      key = "0xAB22A52B64CF60D3";
      signByDefault = true;
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
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
    };
  };

  alacritty = {
    enable = true;

    settings = {
      import = ["/Users/jj/.config/alacritty/themes/catppuccin-mocha.toml"];

      env = {
        TERM = "xterm-256color";
      };

      cursor.style = {
        shape = "Block";
        blinking = "Off";
      };

      font = {
        size = 15.0;

        normal = {
          family = "FiraCode Nerd Font";
          style = "Regular";
        };

        bold = {
          family = "FiraCode Nerd Font";
          style = "Bold";
        };

        italic = {
          family = "FiraCode Nerd Font";
          style = "Italic";
        };
      };

      window = {
        title = user;
        opacity = 0.85;

        padding = {
          x = 5;
          y = 5;
        };
      };
    };
  };

  kitty = {
    enable = true;
    font.name = "FiraCode Nerd Font Mono";
    font.size = 15;
    theme = "Catppuccin-Mocha";
    extraConfig = ''
      background_opacity 0.85
      hide_window_decorations titlebar-and-corners
      window_margin_width 5 5 10 5
      tab_bar_style powerline
    '';
  };

  tmux = {
    enable = true;
    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -ag terminal-overrides ",xterm-256color:RGB"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      yank
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
        '';
      }
    ];
  };

  starship = {
    enable = true;
    enableZshIntegration = true;
    settings =
      {
        palette = "catppuccin_mocha";
        command_timeout = 3000;
        add_newline = true;

        character = {
          success_symbol = "[λ](bold green)";
          error_symbol = "[✗](bold red)";
        };

        directory = {
          read_only = " ";
          truncate_to_repo = true;
          truncation_length = 2;
        };

        aws.symbol = "  ";
        buf.symbol = " ";
        c.symbol = " ";
        conda.symbol = " ";
        dart.symbol = " ";
        docker_context.symbol = " ";
        elixir.symbol = " ";
        elm.symbol = " ";
        git_branch.symbol = " ";
        golang.symbol = " ";
        haskell.symbol = " ";
        hg_branch.symbol = " ";
        java.symbol = " ";
        julia.symbol = " ";
        lua.symbol = " ";
        memory_usage.symbol = " ";
        meson.symbol = "喝 ";
        nim.symbol = " ";
        nix_shell.symbol = " ";
        nodejs.symbol = " ";
        package.symbol = " ";
        python.symbol = " ";
        rlang.symbol = "ﳒ ";
        ruby.symbol = " ";
        rust.symbol = " ";
        scala.symbol = " ";
        spack.symbol = "🅢  ";
      }
      // builtins.fromTOML (builtins.readFile
        (pkgs.fetchFromGitHub
          {
            owner = "catppuccin";
            repo = "starship";
            rev = "5629d2356f62a9f2f8efad3ff37476c19969bd4f";
            sha256 = "sha256-nsRuxQFKbQkyEI4TXgvAjcroVdG+heKX5Pauq/4Ota0=";
          }
          + /palettes/mocha.toml));
  };

  java = {
    enable = true;
    package = pkgs.jdk22;
  };
}
