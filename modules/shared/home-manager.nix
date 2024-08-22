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

  oh-my-posh = {
    enable = true;
    enableBashIntegration = true;
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

  java = {
    enable = true;
    package = pkgs.jdk22;
  };
}
