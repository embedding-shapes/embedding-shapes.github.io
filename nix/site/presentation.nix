{ lib, h }:

let
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

in {
  renderIndexPage = { posts }: renderPage {
    title = "embedding-shapes";
    path = "/";
    content = [
      [ "p" { class = "intro"; } "Welcome to my blog. I write about technology, Nix, and other topics." ]
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
        [ "li" "Bluesky: " [ "a" { href = "https://bsky.app/profile/embedding-shapes.bsky.social"; } "embedding-shapes.bsky.social" ] ]
        [ "li" "Mastodon: " [ "a" { href = "https://mastodon.social/@embedding_shapes"; } "@embedding_shapes@mastodon.social" ] ]
        [ "li" "Email: " [ "a" { href = "mailto:embedding-shapes@proton.me"; } "embedding-shapes@proton.me" ] ]
      ]
      (lib.optional (repoVersions != "") (h.raw repoVersions))
    ];
  };

  renderPostPage = { post }: renderPage {
    title = post.title;
    content = [
      [ "h1" post.title ]
      (lib.optional (post.date != null) [ "p" { class = "post-date"; } post.date ])
      (h.raw post.body)
      (lib.optional (post.versions != "") (h.raw post.versions))
    ];
  };
}
