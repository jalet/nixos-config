{ pkgs }:
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
  neofetch
  oh-my-zsh
  oh-my-posh
  openssh
  qemu
  slack
  wget
  zip

  # Encryption and security tools
  ssm-session-manager-plugin
  yubikey-agent
  yubikey-manager
  _1password-cli
  _1password-gui

  # Text and terminal utilities
  ctop
  htop
  jq
  neovim
  ripgrep
  tmux
  tree
  unrar
  unzip

  # Languages, LSPs and Formatters
  cargo
  go
  luarocks
  nodejs_20
  rustc
  terraform
  terraform-docs
  terraform-ls
  tree-sitter

  # Fonts
  fira-code
  fira-code-symbols
  fira-code-nerdfont
  font-manager
  font-awesome_5
  noto-fonts
]
