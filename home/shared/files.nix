{ pkgs
, homeDirectory
, inputs
, ...
}:
let
in
{
  "${homeDirectory}/.config/nvim" = {
    source = inputs.jalet-nvim;
    recursive = true;
  };
}

