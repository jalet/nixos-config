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
        "tmux"
        "aws"
        "docker"
        "fzf"
        "gh"
        "git"
        "github"
        "podman"
        "ssh-agent"
        "sudo"
        "terraform"
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


      export DOCKER_HOST=unix://$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')

      export PATH=$PATH:$HOME/.cargo/bin
      export PATH=$PATH:/opt/homebrew/bin
    '';

    shellAliases = {
      ls = "eza --color=always --icons=always";
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

  fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
    colors = {
      "bg"= "#1e1e2e";
      "bg+" = "#313244";
      "fg" = "#cdd6f4";
      "fg+" = "#cdd6f4";
      "header" = "#f38ba8";
      "hl"= "#f38ba8";
      "hl+" = "#f38ba8";
      "info" = "#cba6f7";
      "marker" = "#b4befe";
      "pointer" = "#f5e0dc";
      "prompt" = "#cba6f7";
      "selected-bg" = "#45475a";
      "spinner"= "#f5e0dc";
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

      gpg = {
        format = "ssh";
      };

      user = {
        signingkey = "~/.ssh/id_ed25519_sk_rk_me.pub";
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

  wezterm = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    extraConfig = ''
      return {
        color_scheme = "catppuccin-mocha";
        enable_tab_bar = false;
        font = wezterm.font("FiraCode Nerd Font Mono");
        font_size = 14;
        front_end = "WebGpu";
        macos_window_background_blur = 20;
        window_background_opacity = 0.9;
        window_decorations = "RESIZE";
      }
    '';
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
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
          set -oqg @catppuccin_window_text "#W"
          set -oqg @catppuccin_window_current_text "#W"
        '';
      }
    ];
  };

  oh-my-posh = {
    enable = true;
    enableZshIntegration = true;
    settings = builtins.fromTOML(''
      "$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json"
      final_space = true
      version = 2
      disable_notice = true

      [palette]
      os = "#ACB0BE"
      closer = "p:os"
      pink = "#F5C2E7"
      lavender = "#B4BEFE"
      blue = "#89B4FA"

      [[blocks]]
      alignment = "left"
      type = "prompt"

        [[blocks.segments]]
        foreground = "p:os"
        style = "plain"
        template = "λ "
        type = "text"

        [[blocks.segments]]
        foreground = "p:blue"
        style = "plain"
        template = "{{ .UserName }} "
        type = "session"

        [[blocks.segments]]
        foreground = "p:pink"
        style = "plain"
        template = "{{ .Path }} "
        type = "path"

          [blocks.segments.properties]
          folder_icon = "...."
          home_icon = "~"
          style = "agnoster_short"

        [[blocks.segments]]
        foreground = "p:lavender"
        template = "{{ .HEAD }} "
        style = "plain"
        type = "git"

          [blocks.segments.properties]
          branch_icon = " "
          cherry_pick_icon = " "
          commit_icon = " "
          fetch_status = false
          fetch_upstream_icon = false
          merge_icon = " "
          no_commits_icon = " "
          rebase_icon = " "
          revert_icon = " "
          tag_icon = " "

        [[blocks.segments]]
        style = "plain"
        foreground = "p:closer"
        template = ""
        type = "text"
    '');
  };
}
