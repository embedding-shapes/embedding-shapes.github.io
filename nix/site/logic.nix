{ pkgs }:

let
  lib = pkgs.lib;

  projectRoot = ../..;
  postsDir = projectRoot + "/posts";

  repoRoot = builtins.getEnv "BLOG_REPO_ROOT";
  gitDir =
    if builtins.pathExists (projectRoot + "/.git") then (projectRoot + "/.git")
    else if repoRoot != "" && builtins.pathExists (repoRoot + "/.git")
      then builtins.path { path = repoRoot + "/.git"; name = "blog-git-dir"; }
      else null;

  # Convert markdown to HTML using pandoc (supports GFM tables + syntax highlighting)
  # Pandoc automatically skips YAML frontmatter
  mdToHtml = mdPath: builtins.readFile (pkgs.runCommandLocal "md-to-html" {} ''
    ${pkgs.pandoc}/bin/pandoc -f gfm -t html --highlight-style=breezedark ${mdPath} -o $out
  '');

  versions = import ../versions.nix { inherit pkgs lib gitDir mdToHtml; };

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
      versions = versions.postVersionsHtml filename;
    }) postFiles;

  # Sort posts by date, newest first
  sortedPosts = lib.sort (a: b: a.date > b.date) posts;

in {
  posts = sortedPosts;
  inherit highlightCss;
  inherit (versions) repoVersions;
}

