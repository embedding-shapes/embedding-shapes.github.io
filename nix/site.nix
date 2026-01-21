{ pkgs, niccup }:

let
  site = import ./site/logic.nix { inherit pkgs; };
  ui = import ./site/presentation.nix { lib = pkgs.lib; h = niccup.lib; };

  indexHtml = pkgs.writeText "index.html" (ui.renderIndexPage { posts = site.posts; });
  postsHtml = pkgs.writeText "posts.html" (ui.renderPostsIndexPage { posts = site.posts; });
  aboutHtml = pkgs.writeText "about.html" (ui.renderAboutPage { repoVersions = site.repoVersions; });
  rssXml = pkgs.writeText "rss.xml" (ui.renderRssFeed { posts = site.posts; });
  atomXml = pkgs.writeText "atom.xml" (ui.renderAtomFeed { posts = site.posts; });

in {
  default = pkgs.runCommand "blog" {} ''
    mkdir -p $out
    cp ${../style.css} $out/style.css
    cp ${site.highlightCss} $out/highlight.css
    cp ${../favicon.svg} $out/favicon.svg
    cp -r ${../content} $out/content
    cp ${indexHtml} $out/index.html
    cp ${rssXml} $out/rss.xml
    cp ${atomXml} $out/atom.xml
    mkdir -p $out/posts
    cp ${postsHtml} $out/posts/index.html
    mkdir -p $out/about
    cp ${aboutHtml} $out/about/index.html
    ${builtins.concatStringsSep "\n" (map (post:
      "mkdir -p $out/${post.slug} && cp ${pkgs.writeText "index.html" (ui.renderPostPage { inherit post; })} $out/${post.slug}/index.html"
    ) site.posts)}
  '';
}
