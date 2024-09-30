{ catppuccin, ... }:
{
  imports = [
    catppuccin.homeManagerModules.catppuccin
    ./home.nix
    ../shared
  ];
}
	    
