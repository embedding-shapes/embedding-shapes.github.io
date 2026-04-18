{ pkgs
, postsDir
, supportedLocales
, defaultLocale
, reservedPostSlugs
, mdToHtml
}:

let
  lib = pkgs.lib;
  frontmatter = import ./frontmatter.nix { inherit lib; };

  ensure = condition: message:
    if condition then true else builtins.throw message;

  filenameToTitle = baseName:
    let
      words = lib.splitString "-" baseName;
      capitalize = word:
        let chars = lib.stringToCharacters word;
        in
          if chars == [] then ""
          else lib.concatStrings ([ lib.toUpper (builtins.head chars) ] ++ builtins.tail chars);
    in
      lib.concatStringsSep " " (map capitalize words);

  parseFilename = filename:
    let
      localized = builtins.match "^(.*)\\.([a-z][a-z])\\.md$" filename;
      _suffixCheck =
        ensure (lib.hasSuffix ".md" filename) "Post `${filename}` does not end in `.md`.";
    in
      if localized != null then {
        groupKey = builtins.elemAt localized 0;
        locale = builtins.elemAt localized 1;
      } else {
        groupKey = lib.removeSuffix ".md" filename;
        locale = defaultLocale;
      };

  postFiles = lib.filterAttrs (name: type:
    type == "regular" && lib.hasSuffix ".md" name
  ) (builtins.readDir postsDir);

  variants = lib.mapAttrsToList (filename: _:
    let
      fileInfo = parseFilename filename;
      _localeCheck =
        ensure (lib.elem fileInfo.locale supportedLocales)
          "Post `${filename}` uses unsupported locale `${fileInfo.locale}`.";

      parsed = frontmatter.parse {
        content = builtins.readFile (postsDir + "/${filename}");
        sourceName = filename;
      };
      slug =
        if parsed.slug != null && parsed.slug != "" then parsed.slug
        else builtins.throw "Post `${filename}` is missing required `slug` frontmatter.";
      _reservedSlugCheck =
        ensure (!(lib.elem slug reservedPostSlugs))
          "Post `${filename}` uses reserved slug `${slug}`.";
      bodyPath = pkgs.writeText "post-${fileInfo.groupKey}-${fileInfo.locale}.md" parsed.bodyMarkdown;
    in {
      body = mdToHtml bodyPath;
      date = parsed.date;
      filename = filename;
      groupKey = fileInfo.groupKey;
      locale = fileInfo.locale;
      slug = slug;
      title =
        if parsed.title != null then parsed.title
        else filenameToTitle fileInfo.groupKey;
    }
  ) postFiles;

  variantsByGroup = lib.foldl' (groups: variant:
    groups // {
      ${variant.groupKey} = (groups.${variant.groupKey} or []) ++ [ variant ];
    }
  ) {} variants;

  groupedPosts = lib.mapAttrsToList (groupKey: groupVariants:
    let
      locales = map (variant: variant.locale) groupVariants;
      uniqueLocales = lib.unique locales;
      _duplicateLocaleCheck =
        ensure (builtins.length locales == builtins.length uniqueLocales)
          "Post group `${groupKey}` defines the same locale more than once.";
      translations = lib.listToAttrs (map (variant: {
        name = variant.locale;
        value = variant;
      }) groupVariants);
      english =
        if builtins.hasAttr defaultLocale translations then translations.${defaultLocale}
        else builtins.throw "Post group `${groupKey}` is missing its English source file.";
    in {
      availableLocales = lib.filter (locale: builtins.hasAttr locale translations) supportedLocales;
      date = english.date;
      id = groupKey;
      inherit translations;
    }
  ) variantsByGroup;

  sortedGroups =
    let
      dateKey = group: if group.date == null then "0000-00-00" else group.date;
    in lib.sort (a: b: dateKey a > dateKey b) groupedPosts;

  checkedSlugs = lib.foldl' (seen: group:
    lib.foldl' (innerSeen: locale:
      let
        variant = group.translations.${locale};
        key = "${locale}:${variant.slug}";
        existing = innerSeen.${key} or null;
        _duplicateSlugCheck =
          ensure (existing == null)
            "Post `${variant.filename}` reuses locale slug `${variant.slug}` already used by `${existing.filename}`.";
      in
        innerSeen // { ${key} = variant; }
    ) seen group.availableLocales
  ) {} sortedGroups;

in {
  byId = lib.listToAttrs (map (group: {
    name = group.id;
    value = group;
  }) sortedGroups);
  groups = builtins.seq checkedSlugs sortedGroups;
}
