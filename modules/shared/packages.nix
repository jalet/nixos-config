{pkgs}:
with pkgs; [
  # General packages for development and system management
  awscli2
  awslogs
  bash-completion
  bat
  btop
  coreutils
  drawio
  eza
  fd
  fzf
  iftop
  ipcalc
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
  pwgen
  # ssm-session-manager-plugin  # broken in nixpkgs - Go vendoring issue
  tailscale
  yubikey-agent
  yubikey-manager
  sops

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
  pulumi
  python314
  rustc
  terraform
  terraform-docs
  terraform-ls
  tflint
  tree-sitter
  uv

  # kubernetes
  cilium-cli
  hubble
  istioctl
  k9s
  kubecolor
  kubectl
  kubectl-cnpg
  kubectx
  kubernetes-helm
  (stdenv.mkDerivation rec {
    pname = "talosctl";
    version = "1.12.1";
    src = pkgs.fetchurl {
      url = "https://github.com/siderolabs/talos/releases/download/v${version}/talosctl-darwin-arm64";
      hash = "sha256-Wwg2olmKliAgxdlqQoZ3fBGqiKdxooRFcBDIyHDKKJc=";
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/talosctl
      chmod +x $out/bin/talosctl
    '';
  })
]
