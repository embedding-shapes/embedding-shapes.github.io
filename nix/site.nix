{ pkgs, niccup }:

let
  lib = pkgs.lib;
  h = niccup.lib;

  postsDir = ../posts;
  repoRoot = builtins.getEnv "BLOG_REPO_ROOT";
  gitDir =
    if builtins.pathExists ../.git then ../.git
    else if repoRoot != "" && builtins.pathExists (repoRoot + "/.git")
      then builtins.path { path = repoRoot + "/.git"; name = "blog-git-dir"; }
      else null;

  # Convert markdown to HTML using pandoc (supports GFM tables + syntax highlighting)
  # Pandoc automatically skips YAML frontmatter
  mdToHtml = mdPath: builtins.readFile (pkgs.runCommandLocal "md-to-html" {} ''
    ${pkgs.pandoc}/bin/pandoc -f gfm -t html --highlight-style=breezedark ${mdPath} -o $out
  '');

  versions = import ./versions.nix { inherit pkgs lib gitDir mdToHtml; };
  inherit (versions) postVersionsHtml repoVersions;

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

  navLink = { href, label, key, active }: [
    "a"
    (if key == active then { inherit href; "aria-current" = "page"; } else { inherit href; })
    label
  ];

  header = navActive: [ "header"
    [ "a" { href = "/"; } "embedding-shapes" ]
    [ "nav"
      (navLink { href = "/"; label = "Home"; key = "home"; active = navActive; })
      (navLink { href = "/posts/"; label = "Posts"; key = "posts"; active = navActive; })
      (navLink { href = "/about/"; label = "About"; key = "about"; active = navActive; })
    ]
  ];

  footer = [ "footer" [ "p" "Built with "  [ "a" { href = "https://embedding-shapes.github.io/niccup/"; } "niccup" ]] ];

  postList = [ "ul" { class = "post-list"; }
    (map (p: [ "li" [ "a" { href = "/${p.slug}/"; } p.title ] ]) sortedPosts)
  ];

  renderPage = { title, content, path ? null }:
    let
      navActive =
        if path == "/" then "home"
        else if path == "/posts/" then "posts"
        else if path == "/about/" then "about"
        else null;
    in h.renderPretty [
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
      (header navActive)
      [ "main" content ]
      footer
    ]
  ];

  indexHtml = pkgs.writeText "index.html" (renderPage {
    title = "embedding-shapes";
    path = "/";
    content = [
      [ "p" { class = "intro"; } "Welcome to my blog. I write about technology, Nix, and other topics." ]
      [ "h2" "Recent Posts" ]
      postList
    ];
  });

  postsHtml = pkgs.writeText "posts.html" (renderPage {
    title = "Posts";
    path = "/posts/";
    content = [
      [ "h1" "Posts" ]
      postList
    ];
  });

  aboutHtml = pkgs.writeText "about.html" (renderPage {
    title = "About";
    path = "/about/";
    content = [
      [ "h1" "About" ]
      [ "ul"
        [ "li" "GitHub: " [ "a" { href = "https://github.com/embedding-shapes/"; } "embedding-shapes" ] ]
        [ "li" "Bluesky: " [ "a" { href = "https://bsky.app/profile/embedding-shapes.bsky.social"; } "embedding-shapes.bsky.social" ] ]
        [ "li" "Mastodon: " [ "a" { href = "https://mastodon.social/@embedding_shapes"; } "@embedding_shapes@mastodon.social" ] ]
        [ "li" "Email: " [ "a" { href = "mailto:embedding-shapes@proton.me"; } "embedding-shapes@proton.me" ] ]
      ]
      (lib.optional (repoVersions != "") (h.raw repoVersions))
    ];
  });

in {
  default = pkgs.runCommand "blog" {} ''
    mkdir -p $out
    cp ${../style.css} $out/style.css
    cp ${highlightCss} $out/highlight.css
    cp ${../favicon.svg} $out/favicon.svg
    cp -r ${../content} $out/content
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
}
