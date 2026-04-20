{ lib, h, common, siteModel, versions }:

let
  postList = { groups, showLanguages }:
    [ "ul" { class = "post-list"; }
      (map (entry:
        [ "li"
          [ "a" { class = "post-link"; href = entry.href; }
            (lib.optionals (entry.date != null) [
              [ "span" { class = "post-date"; } entry.date ]
              [ "br" ]
            ])
            [ "span" { class = "post-title"; } entry.title ]
          ]
          (lib.optionals showLanguages [
            (common.renderLanguageLinks {
              class = "post-languages";
              links = entry.languageLinks;
            })
          ])
        ]
      ) groups)
    ];

in {
  renderAboutPage = page:
    let
      strings = siteModel.stringsFor page.locale;
      repoVersionsHtml = versions.repoVersionsHtml strings.repoVersions;
    in common.renderPage {
      active = "about";
      alternates = siteModel.languageAlternatesForPage "about";
      canonicalPath = page.path;
      content = [
        [ "h1" strings.about ]
        [ "ul"
          [ "li" "GitHub: " [ "a" { href = "https://github.com/embedding-shapes/"; } "embedding-shapes" ] ]
          [ "li" "Bluesky: " [ "a" { href = "https://bsky.app/profile/emsh.cat"; } "@emsh.cat" ] ]
          [ "li" "Mastodon: " [ "a" { href = "https://mastodon.social/@embedding_shapes"; } "@embedding_shapes@mastodon.social" ] ]
          [ "li" "${strings.email}: " [ "a" { href = "mailto:embedding-shapes@proton.me"; } "embedding-shapes@proton.me" ] ]
        ]
        (lib.optional (repoVersionsHtml != "") (h.raw repoVersionsHtml))
      ];
      languageLinks = siteModel.pageLanguageLinks "about" page.locale;
      locale = page.locale;
      title = page.title;
      xDefaultPath = "/en/about/";
    };

  renderHomePage = page:
    let strings = siteModel.stringsFor page.locale;
    in common.renderPage {
      active = "home";
      alternates = siteModel.languageAlternatesForPage "home";
      canonicalPath = page.path;
      content = [
        [ "p" { class = "intro"; } strings.intro ]
        [ "h2" strings.recentPosts ]
        (postList {
          groups = siteModel.listingEntriesFor page.locale siteModel.postGroups;
          showLanguages = false;
        })
      ];
      languageLinks = siteModel.pageLanguageLinks "home" page.locale;
      locale = page.locale;
      title = page.title;
      xDefaultPath = "/en/";
    };

  renderPostPage = page:
    let
      strings = siteModel.stringsFor page.locale;
      versionsHtml = versions.postVersionsHtml {
        filenames = map (locale: page.group.translations.${locale}.filename) page.group.availableLocales;
        summary = strings.versions;
      };
    in common.renderPage {
      active = null;
      alternates = siteModel.languageAlternatesForPost page.group;
      canonicalPath = page.path;
      content = [
        [ "h1" page.post.title ]
        (lib.optional (page.group.date != null) [ "p" { class = "post-date"; } page.group.date ])
        (h.raw page.post.body)
        (lib.optional (versionsHtml != "") (h.raw versionsHtml))
      ];
      languageLinks = siteModel.postLanguageLinks page.group page.locale;
      locale = page.locale;
      title = page.title;
      xDefaultPath = "/en/${page.group.translations.en.slug}/";
    };

  renderPostsPage = page:
    let strings = siteModel.stringsFor page.locale;
    in common.renderPage {
      active = "posts";
      alternates = siteModel.languageAlternatesForPage "posts";
      canonicalPath = page.path;
      content = [
        [ "h1" strings.posts ]
        (postList {
          groups = siteModel.listingEntriesFor page.locale siteModel.postGroups;
          showLanguages = true;
        })
      ];
      languageLinks = siteModel.pageLanguageLinks "posts" page.locale;
      locale = page.locale;
      title = page.title;
      xDefaultPath = "/en/posts/";
    };
}
