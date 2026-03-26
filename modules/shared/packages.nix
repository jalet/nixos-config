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
  age
  gnupg
  pwgen
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
  cargo
  cargo-audit
  clippy
  go
  lua
  luarocks
  nodejs_22
  pulumi
  pulumiPackages.pulumi-go
  python314
  rustc
  rustfmt
  terraform
  terraform-docs
  terraform-ls
  tflint
  tree-sitter
  uv

  # kubernetes
  argocd
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
