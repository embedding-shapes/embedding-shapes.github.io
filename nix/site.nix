{ pkgs, niccup }:

let
  lib = pkgs.lib;
  config = import ./site/data/config.nix;
  i18n = import ./site/data/i18n.nix { inherit lib; };
  routes = import ./site/model/routes.nix { inherit lib config i18n; };

  projectRoot = ../.;
  postsDir = projectRoot + "/posts";
  repoRoot = builtins.getEnv "BLOG_REPO_ROOT";
  gitDir =
    if builtins.pathExists (projectRoot + "/.git") then projectRoot + "/.git"
    else if repoRoot != "" && builtins.pathExists (repoRoot + "/.git")
      then builtins.path { name = "blog-git-dir"; path = repoRoot + "/.git"; }
      else null;

  mdToHtml = mdPath: builtins.readFile (pkgs.runCommandLocal "md-to-html" {} ''
    ${pkgs.pandoc}/bin/pandoc -f gfm -t html --highlight-style=breezedark ${mdPath} -o $out
  '');

  highlightCss = pkgs.runCommandLocal "highlight.css" {} ''
    echo '```c
    x
    ```' | ${pkgs.pandoc}/bin/pandoc -f gfm -t html --standalone --highlight-style=breezedark \
      | ${pkgs.gnused}/bin/sed -n '/code span\./,/^[[:space:]]*<\/style>/p' \
      | ${pkgs.gnugrep}/bin/grep -v '</style>' > $out
  '';

  posts = import ./site/content/posts.nix {
    defaultLocale = i18n.defaultLocale;
    inherit mdToHtml pkgs postsDir;
    reservedPostSlugs = config.reservedPostSlugs;
    supportedLocales = i18n.locales;
  };

  versions = import ./versions.nix {
    inherit gitDir lib mdToHtml pkgs;
  };

  siteModel = import ./site/model/site.nix {
    inherit config i18n lib posts routes;
  };

  common = import ./site/render/common.nix {
    inherit config i18n lib routes;
    h = niccup.lib;
  };

  pages = import ./site/render/pages.nix {
    inherit common lib siteModel versions;
    h = niccup.lib;
  };

  feeds = import ./site/render/feeds.nix {
    inherit config lib siteModel;
    h = niccup.lib;
  };

  renderRedirect = import ./site/render/redirect.nix {
    h = niccup.lib;
    inherit routes;
  };

  writeFile = path: text: {
    inherit path;
    source = pkgs.writeText (builtins.replaceStrings [ "/" ] [ "-" ] path) text;
  };

  htmlFiles = map (page:
    writeFile page.output (
      if page.kind == "home" then pages.renderHomePage page
      else if page.kind == "posts" then pages.renderPostsPage page
      else if page.kind == "about" then pages.renderAboutPage page
      else pages.renderPostPage page
    )
  ) siteModel.htmlPages;

  feedFiles = map (feed:
    writeFile feed.output (
      if feed.format == "atom" then feeds.renderAtomFeed feed
      else feeds.renderRssFeed feed
    )
  ) (siteModel.localeFeeds ++ siteModel.compatibilityFeeds);

  extraFiles = [
    (writeFile siteModel.sitemapPath (feeds.renderSitemapXml {}))
    (writeFile siteModel.robotsPath (feeds.renderRobotsTxt {}))
  ];

  redirectFiles = map (redirect: writeFile redirect.output (renderRedirect redirect)) siteModel.redirects;
  generatedFiles = htmlFiles ++ feedFiles ++ extraFiles ++ redirectFiles;

in {
  default = pkgs.runCommand "blog" {} ''
    mkdir -p $out
    cp ${../CNAME} $out/CNAME
    cp ${../style.css} $out/style.css
    cp ${highlightCss} $out/highlight.css
    cp ${../favicon.svg} $out/favicon.svg
    cp -r ${../content} $out/content
    ${builtins.concatStringsSep "\n" (map (file:
      "install -Dm644 ${file.source} $out/${file.path}"
    ) generatedFiles)}
  '';
}
