{
  user,
  config,
  pkgs,
  ...
}: let
  Mocha = "Catppuccin Mocha.tmTheme";
  HOME = "${config.users.users.${user}.home}";
in {
  "${HOME}/.config/bat/themes/${Mocha}".text =
    builtins.readFile
    (pkgs.fetchFromGitHub
      {
        owner = "catppuccin";
        repo = "bat";
        rev = "2bafe4454d8db28491e9087ff3a1382c336e7d27";
        sha256 = "sha256-yHt3oIjUnljARaihalcWSNldtaJfVDfmfiecYfbzGs0=";
      }
      + "/themes/${Mocha}");
  
  "${HOME}/.markdownlint.yaml".text = ''
    --- 
    default: true
    MD013:
      tables: false
  '';
}
