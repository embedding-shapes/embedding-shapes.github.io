{ lib, h, config, i18n, routes }:

let
  intersperse = separator: items:
    if items == [] then []
    else if builtins.tail items == [] then [ (builtins.head items) ]
    else [ (builtins.head items) separator ] ++ intersperse separator (builtins.tail items);

  renderLanguageLinks = { class, links }:
    [ "p" { class = class; }
      (intersperse " / " (map (link:
        [ "a"
          ((if link.current then { "aria-current" = "page"; } else {}) // { href = link.href; })
          link.locale
        ]
      ) links))
    ];

  plausibleAnalytics = [
    [ "script" {
      async = true;
      src = "https://plausible.io/js/pa-FG5K-GlhTzYQkb3KeYVzG.js";
    } ]
    [ "script" (h.raw ''
      window.plausible=window.plausible||function(){(plausible.q=plausible.q||[]).push(arguments)},plausible.init=plausible.init||function(i){plausible.o=i||{}};
      plausible.init()
    '') ]
  ];

in {
  inherit renderLanguageLinks;

  renderPage = { active, alternates, canonicalPath, content, locale, title, xDefaultPath, languageLinks }:
    let
      strings = i18n.stringsFor locale;
      navLink = pageKey: label:
        [ "a"
          ((if active == pageKey then { "aria-current" = "page"; } else {})
            // { href = routes.pagePath locale pageKey; })
          label
        ];
    in
      h.renderPretty [
        "html" { lang = locale; }
        [ "head"
          [ "meta" { charset = "utf-8"; } ]
          [ "meta" { content = "width=device-width, initial-scale=1"; name = "viewport"; } ]
          [ "title" title ]
          [ "link" { href = routes.absoluteUrl canonicalPath; rel = "canonical"; } ]
          (map (alternate:
            [ "link" {
              href = routes.absoluteUrl alternate.href;
              hreflang = alternate.locale;
              rel = "alternate";
            } ]
          ) alternates)
          [ "link" {
            href = routes.absoluteUrl xDefaultPath;
            hreflang = "x-default";
            rel = "alternate";
          } ]
          [ "link" { href = "/style.css"; rel = "stylesheet"; } ]
          [ "link" { href = "/highlight.css"; rel = "stylesheet"; } ]
          [ "link" { href = "/favicon.svg"; rel = "icon"; } ]
          [ "link" {
            href = routes.feedPath locale "rss";
            rel = "alternate";
            title = "${config.siteTitle} RSS";
            type = "application/rss+xml";
          } ]
          [ "link" {
            href = routes.feedPath locale "atom";
            rel = "alternate";
            title = "${config.siteTitle} Atom";
            type = "application/atom+xml";
          } ]
          plausibleAnalytics
        ]
        [ "body"
          [ "header"
            [ "div" { class = "brand"; }
              [ "a" { class = "site-title"; href = routes.pagePath locale "home"; } config.siteTitle ]
              (renderLanguageLinks { class = "locale-switcher"; links = languageLinks; })
            ]
            [ "nav"
              (navLink "home" strings.home)
              (navLink "posts" strings.posts)
              (navLink "about" strings.about)
            ]
          ]
          [ "main" content ]
          [ "footer"
            [ "p"
              strings.builtWith
              " "
              [ "a" { href = "https://emsh.cat/niccup/"; } "niccup" ]
              " · "
              [ "a" { href = routes.feedPath locale "atom"; } "Atom" ]
              " / "
              [ "a" { href = routes.feedPath locale "rss"; } "RSS" ]
            ]
          ]
        ]
      ];
}
