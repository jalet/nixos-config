final: prev: {
  neovim = prev.neovim.overrideAttrs (oldAttrs: {
    version = "v0.11.0";
    src = prev.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v0.11.0";
      sha256 = "sha256-UVMRHqyq3AP9sV79EkPUZnVkj0FpbS+XDPPOppp2yFE=";
    };
    patches = [];
  });
}

