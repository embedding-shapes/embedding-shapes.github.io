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

  dropWhile = pred: list:
    if list == [] then []
    else if pred (builtins.head list) then dropWhile pred (builtins.tail list)
    else list;

  # Parse YAML frontmatter (title/date) and derive a markdown body
  # - If frontmatter is present, it's stripped from the body.
  # - If the first non-empty body line is a Markdown H1, it's treated as the title
  #   (only when no frontmatter title is present) and stripped from the body.
  parsePost = content:
    let
      lines = lib.splitString "\n" content;
      hasFrontmatter = lines != [] && (builtins.head lines) == "---";
      tailLines = if lines != [] then builtins.tail lines else [];
      frontmatterEndIdx = if hasFrontmatter
        then lib.lists.findFirstIndex (l: l == "---") null tailLines
        else null;
      frontmatterLines = if frontmatterEndIdx != null
        then lib.take frontmatterEndIdx tailLines
        else [];
      bodyLines0 = if hasFrontmatter && frontmatterEndIdx != null
        then lib.drop (frontmatterEndIdx + 1) tailLines
        else lines;

      trimLine = l: lib.trim l;
      stripOuterQuotes = s:
        let
          len = builtins.stringLength s;
          first = if len > 0 then builtins.substring 0 1 s else "";
          last = if len > 0 then builtins.substring (len - 1) 1 s else "";
        in if len >= 2 && ((first == "\"" && last == "\"") || (first == "'" && last == "'"))
          then builtins.substring 1 (len - 2) s
          else s;
      isBlank = l: (trimLine l) == "";
      bodyLines1 = dropWhile isBlank bodyLines0;

      titleLine = lib.findFirst (l: lib.hasPrefix "title:" l) null frontmatterLines;
      frontmatterTitle = if titleLine != null
        then stripOuterQuotes (trimLine (lib.removePrefix "title:" titleLine))
        else null;

      dateLine = lib.findFirst (l: lib.hasPrefix "date:" l) null frontmatterLines;
      date = if dateLine != null then trimLine (lib.removePrefix "date:" dateLine) else null;

      hasTopLevelH1 = bodyLines1 != [] && lib.hasPrefix "# " (builtins.head bodyLines1);
      h1Title = if hasTopLevelH1 then trimLine (lib.removePrefix "# " (builtins.head bodyLines1)) else null;

      title = if frontmatterTitle != null then frontmatterTitle else h1Title;

      bodyLines2 =
        if hasTopLevelH1
        then dropWhile isBlank (builtins.tail bodyLines1)
        else bodyLines1;
      bodyMarkdown = lib.concatStringsSep "\n" bodyLines2;
    in { inherit title date bodyMarkdown; };

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
      parsed = parsePost content;
      slug = lib.removeSuffix ".md" filename;
      mdBodyPath = pkgs.writeText "post-${slug}.md" parsed.bodyMarkdown;
    in {
      inherit slug;
      title = if parsed.title != null then parsed.title else filenameToTitle filename;
      date = parsed.date;
      body = mdToHtml mdBodyPath;
      versions = versions.postVersionsHtml filename;
    }) postFiles;

  # Sort posts by date, newest first
  sortedPosts =
    let
      dateKey = p: if p.date == null then "0000-00-00" else p.date;
    in lib.sort (a: b: dateKey a > dateKey b) posts;

in {
  posts = sortedPosts;
  inherit highlightCss;
  inherit (versions) repoVersions;
}
