{ pkgs }:

let
  serve = pkgs.writeShellApplication {
    name = "serve";
    runtimeInputs = [ pkgs.python3 pkgs.watchexec ];
    text = ''
      REPO_ROOT="$(pwd)"

      # Initial build
      echo "Building..."
      env BLOG_REPO_ROOT="$REPO_ROOT" nix build --impure

      echo "Serving at http://localhost:8000"
      echo "Watching: posts/, style.css, flake.nix, nix/"
      echo "Press Ctrl+C to stop"

      # Start HTTP server in background
      python3 -m http.server 8000 --directory result &
      server_pid=$!
      trap 'kill $server_pid 2>/dev/null' EXIT

      # Watch and rebuild on changes
      watchexec --watch posts --watch style.css --watch flake.nix --watch nix -- env BLOG_REPO_ROOT="$REPO_ROOT" nix build --impure
    '';
  };
in
{
  meta.description = "Serve the blog locally with live rebuilds.";
  type = "app";
  program = "${serve}/bin/serve";
}
