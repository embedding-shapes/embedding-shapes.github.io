{
  description = "Blog using niccup with dynamic post loading";

  inputs = {
    niccup.url = "github:embedding-shapes/niccup";
    nixpkgs.follows = "niccup/nixpkgs";
  };

  outputs = { self, nixpkgs, niccup }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in import ./nix/site.nix { inherit pkgs niccup; }
      );

      checks =
        let
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
          site = import ./nix/site.nix { inherit pkgs niccup; };
        in {
          ${system} = import ./nix/tests { inherit pkgs; site = site.default; };
        };

      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          serve = import ./nix/serve.nix { inherit pkgs; };
        });
    };
}
