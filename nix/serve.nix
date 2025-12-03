{ pkgs }:

let
  serve = pkgs.writeShellApplication {
    name = "serve";
    runtimeInputs = [ pkgs.python3 pkgs.watchexec ];
    text = ''
      # Initial build
      echo "Building..."
      nix build

      echo "Serving at http://localhost:8000"
      echo "Watching: posts/, style.css, flake.nix"
      echo "Press Ctrl+C to stop"

      # Start HTTP server in background
      python3 -m http.server 8000 --directory result &
      server_pid=$!
      trap 'kill $server_pid 2>/dev/null' EXIT

      # Watch and rebuild on changes
      watchexec --watch posts --watch style.css --watch flake.nix -- nix build
    '';
  };
in
{
  type = "app";
  program = "${serve}/bin/serve";
}
