{ pkgs }:

let
  config = import ../site/data/config.nix;
  i18n = import ../site/data/i18n.nix { lib = pkgs.lib; };

  loadPosts = postsDir: import ../site/content/posts.nix {
    inherit pkgs postsDir;
    defaultLocale = i18n.defaultLocale;
    mdToHtml = path: builtins.readFile path;
    reservedPostSlugs = config.reservedPostSlugs;
    supportedLocales = i18n.locales;
  };

  validPosts = loadPosts ./fixtures/valid/posts;
  goodTaste = validPosts.byId.good-taste;
  invalidResult = builtins.tryEval (
    let brokenPosts = loadPosts ./fixtures/invalid/posts;
    in builtins.deepSeq brokenPosts.groups true
  );

in pkgs.runCommand "content-model-check" {} ''
  test "${goodTaste.translations.en.slug}" = "good-taste"
  test "${goodTaste.translations.sv.slug}" = "god-smak"
  test "${builtins.concatStringsSep "," goodTaste.availableLocales}" = "en,sv"
  test "${if invalidResult.success then "1" else "0"}" = "0"
  echo ok > "$out"
''
