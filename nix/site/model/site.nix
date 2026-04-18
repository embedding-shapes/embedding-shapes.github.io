{ lib, config, i18n, posts, routes }:

let
  latestGroup = lib.findFirst (group: group.date != null) null posts.groups;
  latestDate = if latestGroup != null then latestGroup.date else null;
  feedGroups = lib.take config.feedMaxItems posts.groups;

  stringsFor = locale: i18n.stringsFor locale;

  displayVariantFor = locale: group:
    if builtins.hasAttr locale group.translations
    then group.translations.${locale}
    else group.translations.${i18n.defaultLocale};

  legacyRootPathFor = group:
    if builtins.hasAttr group.id config.legacyRootPosts
    then "/${config.legacyRootPosts.${group.id}}/"
    else null;

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
    {
      description = (stringsFor i18n.defaultLocale).intro;
      entries = compatibilityFeedEntries;
      feedId = routes.absoluteUrl "/";
      format = "atom";
      homeUrl = routes.absoluteUrl "/";
      locale = i18n.defaultLocale;
      output = "atom.xml";
      path = "/atom.xml";
      selfUrl = routes.absoluteUrl "/atom.xml";
      title = config.siteTitle;
    }
    {
      description = (stringsFor i18n.defaultLocale).intro;
      entries = compatibilityFeedEntries;
      feedId = routes.absoluteUrl "/";
      format = "rss";
      homeUrl = routes.absoluteUrl "/";
      locale = i18n.defaultLocale;
      output = "rss.xml";
      path = "/rss.xml";
      selfUrl = routes.absoluteUrl "/rss.xml";
      title = config.siteTitle;
    }
  ];

  localeFeeds = lib.concatMap (locale: [
    {
      description = (stringsFor locale).intro;
      entries = localeFeedEntriesFor locale;
      feedId = routes.absoluteUrl (routes.feedPath locale "atom");
      format = "atom";
      homeUrl = routes.absoluteUrl (routes.homePath locale);
      inherit locale;
      output = routes.feedOutputPath locale "atom";
      path = routes.feedPath locale "atom";
      selfUrl = routes.absoluteUrl (routes.feedPath locale "atom");
      title = config.siteTitle;
    }
    {
      description = (stringsFor locale).intro;
      entries = localeFeedEntriesFor locale;
      feedId = routes.absoluteUrl (routes.feedPath locale "rss");
      format = "rss";
      homeUrl = routes.absoluteUrl (routes.homePath locale);
      inherit locale;
      output = routes.feedOutputPath locale "rss";
      path = routes.feedPath locale "rss";
      selfUrl = routes.absoluteUrl (routes.feedPath locale "rss");
      title = config.siteTitle;
    }
  ]) i18n.locales;

  localeFeedGroupsFor = locale:
    lib.take config.feedMaxItems (
      lib.filter (group: builtins.hasAttr locale group.translations) posts.groups
    );

  localeFeedEntriesFor = locale:
    map (group:
      let variant = group.translations.${locale};
      in {
        body = variant.body;
        date = group.date;
        title = variant.title;
        url = routes.absoluteUrl (routes.postPath variant.locale variant.slug);
      }
    ) (localeFeedGroupsFor locale);

  compatibilityFeedEntries = map (group:
    let
      variant = group.translations.${i18n.defaultLocale};
      legacyPath = legacyRootPathFor group;
    in {
      body = variant.body;
      date = group.date;
      title = variant.title;
      url = routes.absoluteUrl (
        if legacyPath != null then legacyPath
        else routes.postPath variant.locale variant.slug
      );
    }
  ) feedGroups;

  legacyPostRedirects = lib.mapAttrsToList (groupKey: legacySlug:
    let group = posts.byId.${groupKey};
    in {
      output = routes.htmlOutputPath "/${legacySlug}/";
      path = "/${legacySlug}/";
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
