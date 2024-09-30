{ pkgs, userName, userEmail, ... }:
{

  # Let Home Manager install and manage itself.
  home-manager.enable = true;

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

  gpg = {
    enable = true;
    scdaemonSettings = {
      disable-ccid = true;
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

  kitty = {
    enable = true;
    font.name = "FiraCode Nerd Font Mono";
    font.size = 15;
    extraConfig = ''
      background_opacity 0.85
      hide_window_decorations titlebar-and-corners
      window_margin_width 5 5 10 5
      tab_bar_style powerline
    '';
  };

  tmux = {
    enable = true;
    terminal = "tmux-256color";
    shell = "${pkgs.zsh}/bin/zsh";
    keyMode = "vi";
    clock24 = true;
    baseIndex = 0;
    extraConfig = ''
      set -ag terminal-overrides ",xterm-256color:RGB"
    '';
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      yank
      tmux-fzf
    ];
  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = false;
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
    settings = builtins.fromTOML (
      ''
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
      ''
    );
  };
}
