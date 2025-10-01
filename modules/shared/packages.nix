{pkgs}:
with pkgs; [
  # General packages for development and system management
  awscli2
  awslogs
  bash-completion
  bat
  btop
  coreutils
  eza
  fd
  fzf
  fzf-zsh
  iftop
  ipcalc
  kitty
  kitty-themes
  ko
  neofetch
  nmap
  oh-my-posh
  oh-my-zsh
  openssh
  qemu
  watch
  wezterm
  wget
  zip

  # Encryption and security tools
  gnupg
  ssm-session-manager-plugin
  yubikey-agent
  yubikey-manager

  # Text and terminal utilities
  docker
  docker-compose
  ctop
  htop
  jq
  yq
  neovim
  podman
  podman-tui
  ripgrep
  tmux
  tree
  unrar
  unzip

  # Languages, LSPs and Formatters
  alejandra
  bun
  cargo
  claude-code
  go
  lua
  luarocks
  nodejs_22
  rustc
  terraform
  terraform-docs
  terraform-ls
  tflint
  tree-sitter
  pulumi

  # kubernetes
  cilium-cli
  hubble
  istioctl
  k9s
  kubectl
  kubectx
  kubernetes-helm
  (talosctl.overrideAttrs (oldAttrs: rec {
    version = "1.11.1";
    src = pkgs.fetchFromGitHub {
      owner = "siderolabs";
      repo = "talos";
      rev = "v${version}";
      hash = "sha256-G+su1Udkp/IqsU9/TWcEQO4MY8iGC+QM39eMeBUSaDs=";
    };
    vendorHash = "sha256-x9In+TaEuYMB0swuMzyXQRRnWgP1Krg7vKQH4lqDf+c=";
    ldflags = oldAttrs.ldflags or [] ++ [
      "-X github.com/siderolabs/talos/pkg/machinery/version.Tag=v${version}"
    ];
  }))
]
