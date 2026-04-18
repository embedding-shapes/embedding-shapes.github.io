{ lib, config, i18n }:

let
  ensureTrailingSlash = path:
    if lib.hasSuffix "/" path then path else "${path}/";

  trimTrailingSlash = path:
    if path != "/" && lib.hasSuffix "/" path
    then lib.removeSuffix "/" path
    else path;

in {
  absoluteUrl = path: "${config.siteUrl}${path}";

  feedOutputPath = locale: format: "${locale}/${format}.xml";
  feedPath = locale: format: "/${locale}/${format}.xml";

  homePath = locale: "/${locale}/";

  htmlOutputPath = path:
    if path == "/"
    then "index.html"
    else "${trimTrailingSlash (lib.removePrefix "/" (ensureTrailingSlash path))}/index.html";

  pagePath = locale: pageKey:
    if pageKey == "home" then "/${locale}/"
    else if pageKey == "posts" then "/${locale}/posts/"
    else if pageKey == "about" then "/${locale}/about/"
    else builtins.throw "Unknown page key `${pageKey}`.";

  postPath = locale: slug: "/${locale}/${slug}/";
}
