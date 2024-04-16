{pkgs}:
with pkgs; [
  # General packages for development and system management
  alacritty
  awscli2
  bash-completion
  bat
  coreutils
  eza
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
  terraform
  terraform-ls
  terraform-docs
  tflint

  # Rust
  cargo
  rustc

  # nodejs
  nodejs_21
]
