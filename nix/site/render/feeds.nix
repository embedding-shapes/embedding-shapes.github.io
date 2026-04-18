{ lib, h, config, siteModel }:

let
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
    in "${day} ${monthMap.${monthNum} or monthNum} ${year} 00:00:00 +0000";

  xmlEscape = value: builtins.replaceStrings
    [ "&" "<" ">" "\"" "'" ]
    [ "&amp;" "&lt;" "&gt;" "&quot;" "&apos;" ]
    (builtins.toString value);

  xmlAttrs = attrs:
    builtins.concatStringsSep "" (lib.mapAttrsToList (key: value:
      " ${key}=\"${xmlEscape value}\""
    ) attrs);

  xmlLink = { attrs ? {}, content ? null }:
    let renderedAttrs = xmlAttrs attrs;
    in if content == null
      then h.raw "<link${renderedAttrs} />\n"
      else h.raw "<link${renderedAttrs}>${xmlEscape content}</link>\n";

in {
  renderAtomFeed = feed:
    let
      entries = siteModel.feedEntriesFor feed.locale;
      feedUpdated =
        if entries == [] || builtins.head entries == null || (builtins.head entries).date == null
        then "1970-01-01T00:00:00Z"
        else isoDateToRfc3339 (builtins.head entries).date;
    in (xmlHeader "utf-8") + "\n" + (h.render [
      "feed" { xmlns = "http://www.w3.org/2005/Atom"; }
      [ "title" config.siteTitle ]
      [ "id" "${config.siteUrl}${feed.path}" ]
      (xmlLink { attrs = { href = "${config.siteUrl}${feed.path}"; rel = "self"; type = "application/atom+xml"; }; })
      (xmlLink { attrs = { href = "${config.siteUrl}/${feed.locale}/"; }; })
      [ "updated" feedUpdated ]
      (map (entry:
        let updated = if entry.date != null then isoDateToRfc3339 entry.date else feedUpdated;
        in [ "entry"
          [ "title" entry.title ]
          [ "id" entry.url ]
          (xmlLink { attrs = { href = entry.url; }; })
          [ "updated" updated ]
          (lib.optional (entry.date != null) [ "published" updated ])
          [ "content" { type = "html"; } entry.body ]
        ]
      ) entries)
    ]);

  renderRobotsTxt = {}: "User-agent: *\nAllow: /\nSitemap: ${config.siteUrl}/sitemap.xml\n";

  renderRssFeed = feed:
    let
      entries = siteModel.feedEntriesFor feed.locale;
      latestEntry = lib.findFirst (entry: entry.date != null) null entries;
      lastBuildDate = if latestEntry != null then isoDateToRfc822 latestEntry.date else null;
    in (xmlHeader "UTF-8") + "\n" + (h.render [
      "rss" { version = "2.0"; }
      [ "channel"
        [ "title" config.siteTitle ]
        (xmlLink { content = "${config.siteUrl}/${feed.locale}/"; })
        [ "description" (siteModel.stringsFor feed.locale).intro ]
        [ "language" feed.locale ]
        (lib.optional (lastBuildDate != null) [ "lastBuildDate" lastBuildDate ])
        (map (entry: [ "item"
          [ "title" entry.title ]
          (xmlLink { content = entry.url; })
          [ "guid" { isPermaLink = "true"; } entry.url ]
          (lib.optional (entry.date != null) [ "pubDate" (isoDateToRfc822 entry.date) ])
          [ "description" entry.body ]
        ]) entries)
      ]
    ]);

  renderSitemapXml = {}:
    (xmlHeader "UTF-8") + "\n" + (h.render [
      "urlset" { xmlns = "http://www.sitemaps.org/schemas/sitemap/0.9"; }
      (map (entry: [ "url"
        [ "loc" entry.loc ]
        (lib.optional (entry.lastmod != null) [ "lastmod" entry.lastmod ])
      ]) siteModel.sitemapEntries)
    ]);
}
