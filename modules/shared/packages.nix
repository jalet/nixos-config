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
  kitty
  kitty-themes
  neofetch
  oh-my-zsh
  openssh
  qemu
  starship
  tlrc      # tdlr client written in Rust
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
  cargo
  go_1_21
  jdk22
  nodejs_21
  rustc
  terraform
  terraform-docs
  terraform-ls
  tflint
  tree-sitter
]
