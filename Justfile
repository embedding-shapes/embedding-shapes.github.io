default: build

serve:
  nix run .#serve

build:
  BLOG_REPO_ROOT=$(pwd) nix build --impure
