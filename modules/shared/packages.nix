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
  neofetch
  nmap
  oh-my-posh
  oh-my-zsh
  open-policy-agent
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
  go_1_23
  lua
  luarocks
  nodejs_22
  rustc
  terraform
  terraform-docs
  terraform-ls
  tflint
  tree-sitter

  # kubernetes
  cilium-cli
  hubble
  istioctl
  k9s
  kubectl
  kubectx
  kubernetes-helm
]
