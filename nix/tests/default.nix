{ pkgs, site }:

{
  content-model = import ./content-model.nix { inherit pkgs; };
  site-output = import ./site-output.nix { inherit pkgs site; };
}
