default: build

serve:
  nix run .#serve

build:
  nix build
