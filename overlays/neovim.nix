final: prev: {
  neovim = prev.neovim.overrideAttrs (oldAttrs: {
    version = "v0.11.2";
    src = prev.fetchFromGitHub {
      owner = "neovim";
      repo = "neovim";
      rev = "v0.11.2";
      sha256 = "sha256-sNunEdIFrSMqYaNg0hbrSXALRQXxFkdDOl/hhX1L1WA=";
    };
    patches = [];
  });
}

