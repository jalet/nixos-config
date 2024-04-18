{pkgs}:
with pkgs; [
  # General packages for development and system management
  alacritty
  awscli2
  bash-completion
  bat
  coreutils
  eza
  fd
  neofetch
  oh-my-zsh
  openssh
  starship
  wget
  zip

  # Encryption and security tools
  gnupg
  ssm-session-manager-plugin
  yubikey-agent
  yubikey-manager

  # Cloud-related tools and SDKs
  docker
  docker-compose

  # Text and terminal utilities
  htop
  jq
  neovim
  ripgrep
  tmux
  tree
  unrar
  unzip

  # Languages and LSPs
  cargo
  nodejs_21
  rustc
  terraform
  terraform-docs
  terraform-ls
  tree-sitter
  tflint
]
