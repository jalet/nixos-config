{pkgs}:
with pkgs; [
  # General packages for development and system management
  adr-tools
  awscli2
  awslogs
  bash-completion
  bat
  btop
  coreutils
  drawio
  eza
  fastfetch
  fd
  firefox
  fzf
  granted
  iftop
  ipcalc
  ko
  mise
  nmap
  oh-my-zsh
  openssh
  oxide-rs
  qemu
  watch
  wezterm
  wget
  zip

  # Encryption and security tools
  age
  gnupg
  # ssm-session-manager-plugin  # broken in nixpkgs - Go vendoring issue
  yubikey-agent
  yubikey-manager
  step-cli
  sops

  # Text and terminal utilities
  docker
  docker-compose
  claude-monitor
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
  go
  goreleaser
  lua
  luarocks
  nodejs_22
  pulumi-bin
  python314
  rustup
  shellcheck
  tree-sitter-cli
  uv

  # kubernetes
  argocd
  cilium-cli
  hubble
  istioctl
  k9s
  kind
  kubecolor
  kubectl
  kubectl-cnpg
  kubectx
  kubernetes-helm
  talosctl
]
