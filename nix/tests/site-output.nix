{ pkgs, site }:

pkgs.runCommand "site-output-check" {
  nativeBuildInputs = [ pkgs.gnugrep ];
} ''
  failed=0
  check() {
    grep -F "$2" ${site}/"$3" >/dev/null && actual=present || actual=absent
    [ "$1" = "$actual" ] || { echo "$3: expected=$1 actual=$actual value=$2" >&2; failed=1; }
  }

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

  check present 'https://emsh.cat/en/good-taste/' en/good-taste/index.html
  check present 'hreflang="x-default"' en/good-taste/index.html
  check present 'class="post-languages"' en/posts/index.html
  check present 'url=/en/' index.html
  check present 'url=/en/about/' about/index.html
  check present 'url=/en/posts/' posts/index.html
  check present 'url=/en/good-taste/' good-taste/index.html
  check present 'window.location.replace("/en/good-taste/")' good-taste/index.html
  check present '<id>https://emsh.cat/</id>' atom.xml
  check present 'https://emsh.cat/good-taste/' atom.xml
  check present '<link>https://emsh.cat/</link>' rss.xml
  check present '<guid isPermaLink="true">https://emsh.cat/good-taste/</guid>' rss.xml
  check present 'https://emsh.cat/en/good-taste/' en/atom.xml
  check present 'https://emsh.cat/sv/god-smak/' sv/atom.xml
  check absent 'https://emsh.cat/en/good-taste/' sv/atom.xml
  check absent 'https://emsh.cat/en/one-human-one-agent-one-browser/' sv/atom.xml

  [ "$failed" = 0 ]
  echo ok > "$out"
''
