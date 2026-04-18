{ pkgs, site }:

pkgs.runCommand "site-output-check" {
  nativeBuildInputs = [ pkgs.gnugrep ];
} ''
  test -f ${site}/en/index.html
  test -f ${site}/es/index.html
  test -f ${site}/ca/index.html
  test -f ${site}/sv/index.html
  test -f ${site}/en/posts/index.html
  test -f ${site}/en/good-taste/index.html
  test -f ${site}/good-taste/index.html
  test -f ${site}/about/index.html
  test -f ${site}/posts/index.html
  test -f ${site}/atom.xml
  test -f ${site}/en/atom.xml
  test -f ${site}/sv/rss.xml

  grep -F 'https://emsh.cat/en/good-taste/' ${site}/en/good-taste/index.html >/dev/null
  grep -F 'hreflang="x-default"' ${site}/en/good-taste/index.html >/dev/null
  grep -F 'class="post-languages"' ${site}/en/posts/index.html >/dev/null
  grep -F 'url=/en/' ${site}/index.html >/dev/null
  grep -F 'url=/en/about/' ${site}/about/index.html >/dev/null
  grep -F 'url=/en/posts/' ${site}/posts/index.html >/dev/null
  grep -F 'url=/en/good-taste/' ${site}/good-taste/index.html >/dev/null
  grep -F 'window.location.replace("/en/good-taste/")' ${site}/good-taste/index.html >/dev/null

  echo ok > "$out"
''
