{ lib, h }:

let
  siteTitle = "embedding-shapes";
  siteUrl = "https://emsh.cat";
  siteDescription = "Welcome to my blog. I write about technology, Nix, and other topics.";

  homeUrl = "${siteUrl}/";
  postUrl = slug: "${siteUrl}/${slug}/";
  niccupUrl = "${siteUrl}/niccup/";

  xmlHeader = encoding: ''<?xml version="1.0" encoding="${encoding}"?>'';

  isoDateToRfc3339 = date: "${date}T00:00:00Z";
  isoDateToRfc822 = date:
    let
      year = builtins.substring 0 4 date;
      monthNum = builtins.substring 5 2 date;
      day = builtins.substring 8 2 date;
      monthMap = {
        "01" = "Jan"; "02" = "Feb"; "03" = "Mar"; "04" = "Apr";
        "05" = "May"; "06" = "Jun"; "07" = "Jul"; "08" = "Aug";
        "09" = "Sep"; "10" = "Oct"; "11" = "Nov"; "12" = "Dec";
      };
      month = monthMap.${monthNum} or monthNum;
    in "${day} ${month} ${year} 00:00:00 +0000";

  feedMaxItems = 20;

  mkFeedModel = posts:
    let
      feedPosts = lib.take feedMaxItems posts;
      entries = map (post: {
        inherit (post) title date body;
        url = postUrl post.slug;
      }) feedPosts;
      latestEntry = lib.findFirst (e: e.date != null) null entries;
      latestDate = if latestEntry != null then latestEntry.date else null;
    in { inherit entries latestDate; };

  xmlEscape = s: builtins.replaceStrings
    [ "&" "<" ">" "\"" "'" ]
    [ "&amp;" "&lt;" "&gt;" "&quot;" "&apos;" ]
    (builtins.toString s);

  xmlAttrs = attrs: builtins.concatStringsSep "" (lib.mapAttrsToList (k: v: " ${k}=\"${xmlEscape v}\"") attrs);

  xmlLink = { attrs ? {}, content ? null }:
    let renderedAttrs = xmlAttrs attrs;
    in if content == null
      then h.raw "<link${renderedAttrs} />\n"
      else h.raw "<link${renderedAttrs}>${xmlEscape content}</link>\n";

  navLink = { href, label, key, active }: [
    "a"
    (if key == active then { inherit href; "aria-current" = "page"; } else { inherit href; })
    label
  ];

  plausibleAnalytics = [
    [ "script" { async = true; src = "https://plausible.io/js/pa-FG5K-GlhTzYQkb3KeYVzG.js"; } ]
    [ "script" (h.raw ''
      window.plausible=window.plausible||function(){(plausible.q=plausible.q||[]).push(arguments)},plausible.init=plausible.init||function(i){plausible.o=i||{}};
      plausible.init()
    '') ]
  ];

  header = navActive: [ "header"
    [ "a" { href = "/"; } siteTitle ]
    [ "nav"
      (navLink { href = "/"; label = "Home"; key = "home"; active = navActive; })
      (navLink { href = "/posts/"; label = "Posts"; key = "posts"; active = navActive; })
      (navLink { href = "/about/"; label = "About"; key = "about"; active = navActive; })
    ]
  ];

  footer = [ "footer" [ "p" "Built with "  [ "a" { href = niccupUrl; } "niccup" ]] ];

  postList = posts: [ "ul" { class = "post-list"; }
    (map (p: [ "li"
      [ "a" { href = "/${p.slug}/"; }
        (lib.optionals (p.date != null) [
          [ "span" { class = "post-date"; } p.date ]
          [ "br" ]
        ])
        [ "span" { class = "post-title"; } p.title ]
      ]
    ]) posts)
  ];

  renderPage = { title, content, path ? null }:
    let
      navActive =
        if path == "/" then "home"
        else if path == "/posts/" then "posts"
        else if path == "/about/" then "about"
        else null;

      canonicalHref = if path != null then "${siteUrl}${path}" else null;
    in h.renderPretty [
    "html" { lang = "en"; }
    [ "head"
      [ "meta" { charset = "utf-8"; } ]
      [ "meta" { name = "viewport"; content = "width=device-width, initial-scale=1"; } ]
      [ "title" title ]
      (lib.optional (canonicalHref != null) [ "link" { rel = "canonical"; href = canonicalHref; } ])
      [ "link" { rel = "stylesheet"; href = "/style.css"; } ]
      [ "link" { rel = "stylesheet"; href = "/highlight.css"; } ]
      [ "link" { rel = "icon"; href = "/favicon.svg"; } ]
      [ "link" { rel = "alternate"; type = "application/rss+xml"; title = "${siteTitle} RSS"; href = "/rss.xml"; } ]
      [ "link" { rel = "alternate"; type = "application/atom+xml"; title = "${siteTitle} Atom"; href = "/atom.xml"; } ]
      plausibleAnalytics
    ]
    [ "body"
      (header navActive)
      [ "main" content ]
      footer
    ]
  ];

in {
  renderIndexPage = { posts }: renderPage {
    title = siteTitle;
    path = "/";
    content = [
      [ "p" { class = "intro"; } siteDescription ]
      [ "h2" "Recent Posts" ]
      (postList posts)
    ];
  };

  renderPostsIndexPage = { posts }: renderPage {
    title = "Posts";
    path = "/posts/";
    content = [
      [ "h1" "Posts" ]
      (postList posts)
    ];
  };

  renderAboutPage = { repoVersions }: renderPage {
    title = "About";
    path = "/about/";
    content = [
      [ "h1" "About" ]
      [ "ul"
        [ "li" "GitHub: " [ "a" { href = "https://github.com/embedding-shapes/"; } "embedding-shapes" ] ]
        [ "li" "Bluesky: " [ "a" { href = "https://bsky.app/profile/emsh.cat"; } "@emsh.cat" ] ]
        [ "li" "Mastodon: " [ "a" { href = "https://mastodon.social/@embedding_shapes"; } "@embedding_shapes@mastodon.social" ] ]
        [ "li" "Email: " [ "a" { href = "mailto:embedding-shapes@proton.me"; } "embedding-shapes@proton.me" ] ]
      ]
      (lib.optional (repoVersions != "") (h.raw repoVersions))
    ];
  };

  renderPostPage = { post }: renderPage {
    title = post.title;
    path = "/${post.slug}/";
    content = [
      [ "h1" post.title ]
      (lib.optional (post.date != null) [ "p" { class = "post-date"; } post.date ])
      (h.raw post.body)
      (lib.optional (post.versions != "") (h.raw post.versions))
    ];
  };

  renderRssFeed = { posts }:
    let
      m = mkFeedModel posts;
      lastBuildDate = if m.latestDate != null then isoDateToRfc822 m.latestDate else null;
    in (xmlHeader "UTF-8") + "\n" + (h.render [
      "rss" { version = "2.0"; }
      [ "channel"
        [ "title" siteTitle ]
        (xmlLink { content = homeUrl; })
        [ "description" siteDescription ]
        [ "language" "en" ]
        (lib.optional (lastBuildDate != null) [ "lastBuildDate" lastBuildDate ])
        (map (e: [ "item"
          [ "title" e.title ]
          (xmlLink { content = e.url; })
          [ "guid" { isPermaLink = "true"; } e.url ]
          (lib.optional (e.date != null) [ "pubDate" (isoDateToRfc822 e.date) ])
          [ "description" e.body ]
        ]) m.entries)
      ]
    ]);

  renderAtomFeed = { posts }:
    let
      m = mkFeedModel posts;
      feedUpdated = if m.latestDate != null then isoDateToRfc3339 m.latestDate else "1970-01-01T00:00:00Z";
    in (xmlHeader "utf-8") + "\n" + (h.render [
      "feed" { xmlns = "http://www.w3.org/2005/Atom"; }
      [ "title" siteTitle ]
      [ "id" homeUrl ]
      (xmlLink { attrs = { href = homeUrl; }; })
      (xmlLink { attrs = { rel = "self"; type = "application/atom+xml"; href = "${siteUrl}/atom.xml"; }; })
      [ "updated" feedUpdated ]
      (map (e:
        let updated = if e.date != null then isoDateToRfc3339 e.date else feedUpdated;
        in [ "entry"
          [ "title" e.title ]
          [ "id" e.url ]
          (xmlLink { attrs = { href = e.url; }; })
          [ "updated" updated ]
          (lib.optional (e.date != null) [ "published" (isoDateToRfc3339 e.date) ])
          [ "content" { type = "html"; } e.body ]
        ]
      ) m.entries)
    ]);

  renderSitemapXml = { posts }:
    let
      latestPostWithDate = lib.findFirst (p: p.date != null) null posts;
      siteLastMod = if latestPostWithDate != null then latestPostWithDate.date else null;
      urls =
        [
          { loc = homeUrl; lastmod = siteLastMod; }
          { loc = "${siteUrl}/posts/"; lastmod = siteLastMod; }
          { loc = "${siteUrl}/about/"; lastmod = siteLastMod; }
        ]
        ++ (map (p: { loc = postUrl p.slug; lastmod = p.date; }) posts);
    in (xmlHeader "UTF-8") + "\n" + (h.render [
      "urlset" { xmlns = "http://www.sitemaps.org/schemas/sitemap/0.9"; }
      (map (u: [ "url"
        [ "loc" u.loc ]
        (lib.optional (u.lastmod != null) [ "lastmod" u.lastmod ])
      ]) urls)
    ]);

  renderRobotsTxt = {}: "User-agent: *\nAllow: /\nSitemap: ${siteUrl}/sitemap.xml\n";
}
