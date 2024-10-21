{pkgs}:
with pkgs; [
  # General packages for development and system management
  awscli2
  bash-completion
  bat
  coreutils
  eza
  fd
  fzf
  fzf-zsh
  kitty
  kitty-themes
  neofetch
  oh-my-posh
  oh-my-zsh
  open-policy-agent
  openssh
  qemu
  watch
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
  go_1_23
  jdk22
  lua
  luarocks
  nodejs_22
  rustc
  terraform
  terraform-docs
  terraform-ls
  tflint
  tree-sitter
]