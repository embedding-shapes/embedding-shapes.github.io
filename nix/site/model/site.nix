{ lib, config, i18n, posts, routes }:

let
  latestGroup = lib.findFirst (group: group.date != null) null posts.groups;
  latestDate = if latestGroup != null then latestGroup.date else null;

  stringsFor = locale: i18n.stringsFor locale;

  displayVariantFor = locale: group:
    if builtins.hasAttr locale group.translations
    then group.translations.${locale}
    else group.translations.${i18n.defaultLocale};

  pageLanguageLinks = pageKey: currentLocale:
    map (locale: {
      current = locale == currentLocale;
      href = routes.pagePath locale pageKey;
      inherit locale;
    }) i18n.locales;

  postLanguageLinks = group: currentLocale:
    map (locale: {
      current = locale == currentLocale;
      href = routes.postPath locale group.translations.${locale}.slug;
      inherit locale;
    }) group.availableLocales;

  listingEntriesFor = locale: groups:
    map (group:
      let variant = displayVariantFor locale group;
      in {
        date = group.date;
        href = routes.postPath variant.locale variant.slug;
        languageLinks = postLanguageLinks group locale;
        title = variant.title;
      }
    ) groups;

  pageEntries = pageKey: titleFor:
    map (locale: {
      kind = pageKey;
      locale = locale;
      output = routes.htmlOutputPath (routes.pagePath locale pageKey);
      path = routes.pagePath locale pageKey;
      title = titleFor locale;
    }) i18n.locales;

  homePages = pageEntries "home" (_: config.siteTitle);
  postsPages = pageEntries "posts" (locale: (stringsFor locale).posts);
  aboutPages = pageEntries "about" (locale: (stringsFor locale).about);

  postPages = lib.concatMap (group:
    map (locale:
      let variant = group.translations.${locale};
      in {
        group = group;
        kind = "post";
        locale = locale;
        output = routes.htmlOutputPath (routes.postPath locale variant.slug);
        path = routes.postPath locale variant.slug;
        post = variant;
        title = variant.title;
      }
    ) group.availableLocales
  ) posts.groups;

  compatibilityFeeds = [
    { format = "atom"; locale = i18n.defaultLocale; output = "atom.xml"; path = "/atom.xml"; }
    { format = "rss"; locale = i18n.defaultLocale; output = "rss.xml"; path = "/rss.xml"; }
  ];

  localeFeeds = lib.concatMap (locale: [
    {
      format = "atom";
      inherit locale;
      output = routes.feedOutputPath locale "atom";
      path = routes.feedPath locale "atom";
    }
    {
      format = "rss";
      inherit locale;
      output = routes.feedOutputPath locale "rss";
      path = routes.feedPath locale "rss";
    }
  ]) i18n.locales;

  legacyPostRedirects = map (groupKey:
    let group = posts.byId.${groupKey};
    in {
      output = routes.htmlOutputPath "/${groupKey}/";
      path = "/${groupKey}/";
      target = routes.postPath i18n.defaultLocale group.translations.${i18n.defaultLocale}.slug;
    }
  ) config.legacyRootPosts;

  legacySectionRedirects = map (section: {
    output = routes.htmlOutputPath "/${section}/";
    path = "/${section}/";
      target = routes.pagePath i18n.defaultLocale section;
    }) config.legacyRootSections;

in {
  aboutPages = aboutPages;
  compatibilityFeeds = compatibilityFeeds;
  displayVariantFor = displayVariantFor;
  feedEntriesFor = locale:
    let groups = lib.take config.feedMaxItems posts.groups;
    in map (group:
      let variant = displayVariantFor locale group;
      in {
        body = variant.body;
        date = group.date;
        title = variant.title;
        url = routes.absoluteUrl (routes.postPath variant.locale variant.slug);
      }
    ) groups;
  homePages = homePages;
  htmlPages = homePages ++ postsPages ++ aboutPages ++ postPages;
  languageAlternatesForPage = pageKey:
    map (locale: {
      href = routes.pagePath locale pageKey;
      inherit locale;
    }) i18n.locales;
  languageAlternatesForPost = group:
    map (locale: {
      href = routes.postPath locale group.translations.${locale}.slug;
      inherit locale;
    }) group.availableLocales;
  latestDate = latestDate;
  localeFeeds = localeFeeds;
  listingEntriesFor = listingEntriesFor;
  pageLanguageLinks = pageLanguageLinks;
  postGroups = posts.groups;
  postLanguageLinks = postLanguageLinks;
  postPages = postPages;
  postsPages = postsPages;
  redirects = [
    {
      output = "index.html";
      path = "/";
      target = routes.pagePath i18n.defaultLocale "home";
    }
  ] ++ legacySectionRedirects ++ legacyPostRedirects;
  robotsPath = "robots.txt";
  sitemapEntries =
    map (page: {
      lastmod = if page.kind == "post" then page.group.date else latestDate;
      loc = routes.absoluteUrl page.path;
    }) (homePages ++ postsPages ++ aboutPages ++ postPages);
  sitemapPath = "sitemap.xml";
  stringsFor = stringsFor;
}
