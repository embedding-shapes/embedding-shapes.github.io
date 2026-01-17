{
  description = "Blog using niccup with dynamic post loading";

  inputs = {
    niccup.url = "github:embedding-shapes/niccup";
    nixpkgs.follows = "niccup/nixpkgs";
  };

  outputs = { self, nixpkgs, niccup }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib = pkgs.lib;
          h = niccup.lib;

          postsDir = ./posts;
          repoRoot = builtins.getEnv "BLOG_REPO_ROOT";
          gitDir =
            if builtins.pathExists ./.git then ./.git
            else if repoRoot != "" && builtins.pathExists (repoRoot + "/.git")
              then builtins.path { path = repoRoot + "/.git"; name = "blog-git-dir"; }
              else null;

          # Convert markdown to HTML using pandoc (supports GFM tables + syntax highlighting)
          # Pandoc automatically skips YAML frontmatter
          mdToHtml = mdPath: builtins.readFile (pkgs.runCommandLocal "md-to-html" {} ''
            ${pkgs.pandoc}/bin/pandoc -f gfm -t html --highlight-style=breezedark ${mdPath} -o $out
          '');

          postVersionsMd = filename: pkgs.runCommandLocal "post-versions-${lib.removeSuffix ".md" filename}.md" {
            nativeBuildInputs = [ pkgs.git pkgs.gnused pkgs.gnugrep ];
          } ''
            set -euo pipefail
            export GIT_DIR=${gitDir}
            export GIT_OPTIONAL_LOCKS=0

            file="posts/${filename}"
            log="$TMPDIR/log.tsv"

            ${pkgs.git}/bin/git log --follow --date=short --format='%H%x09%ad%x09%s' -- "$file" > "$log" 2>/dev/null || true

            if [ ! -s "$log" ]; then
              : > "$out"
              exit 0
            fi

            {
              echo '<details class="versions">'
              echo '<summary>Versions</summary>'
              echo

              while IFS="$(printf '\t')" read -r hash date subject; do
                short="$(printf '%.7s' "$hash")"
                esc_subject="$(printf '%s' "$subject" | ${pkgs.gnused}/bin/sed -e 's/&/&amp;/g' -e 's/</&lt;/g' -e 's/>/&gt;/g')"

                echo '<details class="version">'
                echo "<summary>$date <code>$short</code> $esc_subject</summary>"
                echo

                echo '````````diff'
                diff_full="$TMPDIR/diff.full"
                diff_body="$TMPDIR/diff.body"
                diff_word="$TMPDIR/diff.word"

                status="$(${pkgs.git}/bin/git show --no-color --format= --name-status -1 "$hash" -- "$file" 2>/dev/null | ${pkgs.gnused}/bin/sed -n '1s/\t.*$//p')"

                case "$status" in
                  A*|D*)
                    ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" -- "$file" 2>/dev/null > "$diff_full" || true
                    ;;
                  *)
                    ${pkgs.git}/bin/git show --no-color --format= --unified=0 --word-diff=porcelain "$hash" -- "$file" 2>/dev/null > "$diff_full" || true
                    ;;
                esac

                ${pkgs.gnused}/bin/sed -n '/^@@ /,$p' "$diff_full" > "$diff_body"

                if ! printf '%s' "$status" | ${pkgs.gnugrep}/bin/grep -qE '^(A|D)'; then
                  ${pkgs.gnused}/bin/sed '/^~$/d' "$diff_body" > "$diff_word"
                  if ${pkgs.gnugrep}/bin/grep -qE '^[+-]' "$diff_word"; then
                    cat "$diff_word" > "$diff_body"
                  else
                    ${pkgs.git}/bin/git show --no-color --format= --unified=0 "$hash" -- "$file" 2>/dev/null > "$diff_full" || true
                    ${pkgs.gnused}/bin/sed -n '/^@@ /,$p' "$diff_full" > "$diff_body"
                  fi
                fi

                cat "$diff_body"
                echo '````````'
                echo
                echo '</details>'
                echo
              done < "$log"

              echo '</details>'
            } > "$out"
          '';

          postVersionsHtml = filename:
            if gitDir == null then ""
            else mdToHtml (postVersionsMd filename);

          # Parse YAML frontmatter to extract date
          # Expects format: ---\ndate: YYYY-MM-DD\n---
          parseFrontmatter = content:
            let
              lines = lib.splitString "\n" content;
              hasFrontmatter = (builtins.head lines) == "---";
              frontmatterEndIdx = if hasFrontmatter
                then lib.lists.findFirstIndex (l: l == "---") null (builtins.tail lines)
                else null;
              frontmatterLines = if frontmatterEndIdx != null
                then lib.take frontmatterEndIdx (builtins.tail lines)
                else [];
              dateLine = lib.findFirst (l: lib.hasPrefix "date:" l) null frontmatterLines;
              date = if dateLine != null
                then lib.trim (lib.removePrefix "date:" dateLine)
                else null;
            in { inherit date; };

          # Generate syntax highlighting CSS from pandoc
          highlightCss = pkgs.runCommandLocal "highlight.css" {} ''
            echo '```c
            x
            ```' | ${pkgs.pandoc}/bin/pandoc -f gfm -t html --standalone --highlight-style=breezedark \
              | ${pkgs.gnused}/bin/sed -n '/code span\./,/^[[:space:]]*<\/style>/p' \
              | ${pkgs.gnugrep}/bin/grep -v '</style>' > $out
          '';

          # Read all .md files from posts directory
          postFiles = lib.filterAttrs (name: type:
            type == "regular" && lib.hasSuffix ".md" name
          ) (builtins.readDir postsDir);

          # Convert filename to title: "hello-world.md" -> "Hello World"
          filenameToTitle = filename:
            let
              slug = lib.removeSuffix ".md" filename;
              words = lib.splitString "-" slug;
              capitalize = s:
                let chars = lib.stringToCharacters s;
                in if chars == [] then ""
                   else lib.concatStrings ([ (lib.toUpper (builtins.head chars)) ] ++ (builtins.tail chars));
            in lib.concatStringsSep " " (map capitalize words);

          # Build post objects from files
          posts = lib.mapAttrsToList (filename: _:
            let
              content = builtins.readFile (postsDir + "/${filename}");
              frontmatter = parseFrontmatter content;
            in {
              slug = lib.removeSuffix ".md" filename;
              title = filenameToTitle filename;
              date = frontmatter.date;
              body = mdToHtml (postsDir + "/${filename}");
              versions = postVersionsHtml filename;
            }) postFiles;

          # Sort posts by date, newest first
          sortedPosts = lib.sort (a: b: a.date > b.date) posts;

          header = [ "header"
            [ "a" { href = "/"; } "embedding-shapes" ]
            [ "nav"
              [ "a" { href = "/"; } "Home" ]
              [ "a" { href = "/posts/"; } "Posts" ]
              [ "a" { href = "/about/"; } "About" ]
            ]
          ];

          footer = [ "footer" [ "p" "Built with "  [ "a" { href = "https://embedding-shapes.github.io/niccup/"; } "niccup" ]] ];

          postList = [ "ul" { class = "post-list"; }
            (map (p: [ "li" [ "a" { href = "/${p.slug}/"; } p.title ] ]) sortedPosts)
          ];

          renderPage = { title, content }: h.renderPretty [
            "html" { lang = "en"; }
            [ "head"
              [ "meta" { charset = "utf-8"; } ]
              [ "meta" { name = "viewport"; content = "width=device-width, initial-scale=1"; } ]
              [ "title" title ]
              [ "link" { rel = "stylesheet"; href = "/style.css"; } ]
              [ "link" { rel = "stylesheet"; href = "/highlight.css"; } ]
              [ "link" { rel = "icon"; href = "/favicon.svg"; } ]
            ]
            [ "body"
              header
              [ "main" content ]
              footer
            ]
          ];

          indexHtml = pkgs.writeText "index.html" (renderPage {
            title = "embedding-shapes";
            content = [
              [ "p" { class = "intro"; } "Welcome to my blog. I write about technology, Nix, and other topics." ]
              [ "h2" "Recent Posts" ]
              postList
            ];
          });

          postsHtml = pkgs.writeText "posts.html" (renderPage {
            title = "Posts";
            content = [
              [ "h1" "Posts" ]
              postList
            ];
          });

          aboutHtml = pkgs.writeText "about.html" (renderPage {
            title = "About";
            content = [
              [ "h1" "About" ]
              [ "ul"
                [ "li" "GitHub: " [ "a" { href = "https://github.com/embedding-shapes/"; } "embedding-shapes" ] ]
                [ "li" "Bluesky: " [ "a" { href = "https://bsky.app/profile/embedding-shapes.bsky.social"; } "embedding-shapes.bsky.social" ] ]
                [ "li" "Email: " [ "a" { href = "mailto:embedding-shapes@proton.me"; } "embedding-shapes@proton.me" ] ]
              ]
            ];
          });

        in {
          default = pkgs.runCommand "blog" {} ''
            mkdir -p $out
            cp ${./style.css} $out/style.css
            cp ${highlightCss} $out/highlight.css
            cp ${./favicon.svg} $out/favicon.svg
            cp -r ${./content} $out/content
            cp ${indexHtml} $out/index.html
            mkdir -p $out/posts
            cp ${postsHtml} $out/posts/index.html
            mkdir -p $out/about
            cp ${aboutHtml} $out/about/index.html
            ${builtins.concatStringsSep "\n" (map (post:
              "mkdir -p $out/${post.slug} && cp ${pkgs.writeText "index.html" (renderPage {
                inherit (post) title;
                content = [
                  (lib.optional (post.date != null) [ "p" { class = "post-date"; } post.date ])
                  (h.raw post.body)
                  (lib.optional (post.versions != "") (h.raw post.versions))
                ];
              })} $out/${post.slug}/index.html"
            ) sortedPosts)}
          '';
        });

      apps = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          serve = import ./nix/serve.nix { inherit pkgs; };
        });
    };
}
