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
  test -f ${site}/rss.xml
  test -f ${site}/en/atom.xml
  test -f ${site}/es/atom.xml
  test -f ${site}/es/rss.xml
  test -f ${site}/ca/atom.xml
  test -f ${site}/ca/rss.xml
  test -f ${site}/sv/atom.xml
  test -f ${site}/sv/rss.xml

  grep -F 'https://emsh.cat/en/good-taste/' ${site}/en/good-taste/index.html >/dev/null
  grep -F 'hreflang="x-default"' ${site}/en/good-taste/index.html >/dev/null
  grep -F 'class="post-languages"' ${site}/en/posts/index.html >/dev/null
  grep -F 'url=/en/' ${site}/index.html >/dev/null
  grep -F 'url=/en/about/' ${site}/about/index.html >/dev/null
  grep -F 'url=/en/posts/' ${site}/posts/index.html >/dev/null
  grep -F 'url=/en/good-taste/' ${site}/good-taste/index.html >/dev/null
  grep -F 'window.location.replace("/en/good-taste/")' ${site}/good-taste/index.html >/dev/null
  grep -F '<id>https://emsh.cat/</id>' ${site}/atom.xml >/dev/null
  grep -F 'https://emsh.cat/good-taste/' ${site}/atom.xml >/dev/null
  grep -F '<link>https://emsh.cat/</link>' ${site}/rss.xml >/dev/null
  grep -F '<guid isPermaLink="true">https://emsh.cat/good-taste/</guid>' ${site}/rss.xml >/dev/null
  grep -F 'https://emsh.cat/en/good-taste/' ${site}/en/atom.xml >/dev/null
  grep -F 'https://emsh.cat/sv/god-smak/' ${site}/sv/atom.xml >/dev/null
  if grep -F '<entry>' ${site}/es/atom.xml >/dev/null; then exit 1; fi
  if grep -F '<item>' ${site}/es/rss.xml >/dev/null; then exit 1; fi
  if grep -F '<entry>' ${site}/ca/atom.xml >/dev/null; then exit 1; fi
  if grep -F '<item>' ${site}/ca/rss.xml >/dev/null; then exit 1; fi
  if grep -F 'https://emsh.cat/en/good-taste/' ${site}/sv/atom.xml >/dev/null; then exit 1; fi
  if grep -F 'https://emsh.cat/en/one-human-one-agent-one-browser/' ${site}/sv/atom.xml >/dev/null; then exit 1; fi

  echo ok > "$out"
''
