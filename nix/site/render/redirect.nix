{ h, routes }:

redirect:
h.renderPretty [
  "html" { lang = "en"; }
  [ "head"
    [ "meta" { charset = "utf-8"; } ]
    [ "meta" { content = "width=device-width, initial-scale=1"; name = "viewport"; } ]
    [ "meta" { content = "0; url=${redirect.target}"; "http-equiv" = "refresh"; } ]
    [ "meta" { content = "noindex"; name = "robots"; } ]
    [ "title" "Redirecting" ]
    [ "link" { href = routes.absoluteUrl redirect.target; rel = "canonical"; } ]
    [ "script" (h.raw "window.location.replace(${builtins.toJSON redirect.target});") ]
  ]
  [ "body"
    [ "p" "Redirecting to " [ "a" { href = redirect.target; } redirect.target ] "." ]
  ]
]
