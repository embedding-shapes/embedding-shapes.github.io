{ lib }:

let
  dropWhile = pred: list:
    if list == [] then []
    else if pred (builtins.head list) then dropWhile pred (builtins.tail list)
    else list;

  trim = line: lib.trim line;

  stripOuterQuotes = value:
    let
      length = builtins.stringLength value;
      first = if length > 0 then builtins.substring 0 1 value else "";
      last = if length > 0 then builtins.substring (length - 1) 1 value else "";
    in
      if length >= 2 && ((first == "\"" && last == "\"") || (first == "'" && last == "'"))
      then builtins.substring 1 (length - 2) value
      else value;

  parseKeyValue = line:
    let
      match = builtins.match "^[[:space:]]*([A-Za-z0-9_-]+):[[:space:]]*(.*)[[:space:]]*$" line;
    in
      if match == null then null else {
        key = builtins.elemAt match 0;
        value = stripOuterQuotes (builtins.elemAt match 1);
      };

  parseMetadata = lines:
    lib.foldl' (metadata: line:
      let parsed = parseKeyValue line;
      in if parsed == null then metadata else metadata // { ${parsed.key} = parsed.value; }
    ) {} lines;

in {
  parse = { content, sourceName, ... }:
    let
      lines = lib.splitString "\n" content;
      hasFrontmatter = lines != [] && builtins.head lines == "---";
      remaining = if lines == [] then [] else builtins.tail lines;
      endIndex =
        if hasFrontmatter
        then lib.lists.findFirstIndex (line: line == "---") null remaining
        else null;
      _ =
        if hasFrontmatter && endIndex == null
        then builtins.throw "Post `${sourceName}` starts frontmatter but never closes it."
        else null;

      frontmatterLines = if endIndex == null then [] else lib.take endIndex remaining;
      bodyLines0 =
        if endIndex == null then lines
        else lib.drop (endIndex + 1) remaining;
      bodyLines1 = dropWhile (line: trim line == "") bodyLines0;
      metadata = parseMetadata frontmatterLines;

      hasTopLevelH1 = bodyLines1 != [] && lib.hasPrefix "# " (builtins.head bodyLines1);
      h1Title =
        if hasTopLevelH1
        then trim (lib.removePrefix "# " (builtins.head bodyLines1))
        else null;
      bodyLines2 =
        if hasTopLevelH1
        then dropWhile (line: trim line == "") (builtins.tail bodyLines1)
        else bodyLines1;
    in {
      bodyMarkdown = lib.concatStringsSep "\n" bodyLines2;
      date = metadata.date or null;
      slug = metadata.slug or null;
      title = metadata.title or h1Title;
    };
}
