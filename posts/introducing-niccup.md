---
date: 2025-12-03
---

# Niccup: Hiccup-like HTML Generation in ~120 Lines of Pure Nix

Ever wish it was really simple to create HTML from just Nix expressions, not even having to deal with function calls or other complexities? With niccup, now there is!

```nix
[ "div#main.container"
  { lang = "en"; }
  [ "h1" "Hello" ] ]
```
```html
<div class="container" id="main" lang="en">
  <h1>Hello</h1>
</div>
```

That's it. Nix data structures in, HTML out. Zero dependencies. Works with flakes or without.

The code is available here: [embedding-shapes/niccup](https://github.com/embedding-shapes/niccup)

The website/docs/API and [some fun examples](https://embedding-shapes.github.io/niccup/examples/quine/) can be found here: [https://embedding-shapes.github.io/niccup/](https://embedding-shapes.github.io/niccup/)

## Why Generate HTML from Nix?

If you're building static sites, documentation, or web artifacts as part of a Nix derivation, you've probably resorted to one of these:

1. String interpolation (`''<div>${title}</div>''`). Works until you need escaping or composition
2. External templating tools. Another dependency, another language, another build step
3. Importing HTML files, no programmatic generation

Niccup takes a different approach: represent HTML as native Nix data structures. This gives you `map`, `filter`, `builtins.concatStringsSep`, and the entire Nix expression language for free. No new syntax to learn. No dependencies to manage.

## The Syntax

An element is a list: `[ tag-spec attrs? children... ]`

### Tag Specs with CSS Shorthand

```nix
"div"
# <div></div>

"input#search"
# <input id="search">

"button.btn.primary"
# <button class="btn primary"></button>

"form#login.auth.dark"
# <form class="auth dark" id="login"></form>
```

### Attributes

The optional second element can be an attribute set:

```nix
[ "a"
  { href = "/about"; target = "_blank"; }
  "About" ]
# <a href="/about" target="_blank">About</a>
```

Classes from the shorthand and attribute set are merged:

```nix
[ "div.base"
  { class = [ "added" "another" ]; }
  "content" ]
# <div class="base added another">content</div>
```

Boolean handling:

```nix
[ "input"
  { type = "checkbox";
    checked = true;
    disabled = false; } ]
# <input checked="checked" type="checkbox">
```

`true` renders as `attr="attr"`. `false` and `null` are omitted entirely.

### Children and Composition

Children can be strings, numbers, nested elements, or lists:

```nix
[ "p"
  "Text with "
  [ "strong" "emphasis" ]
  " and more." ]
# <p>Text with <strong>emphasis</strong> and more.</p>
```

Lists are flattened one level, which makes `map` work naturally:

```nix
[ "ul"
  (map (item: [ "li" item ])
       [ "One" "Two" "Three" ]) ]
# <ul><li>One</li><li>Two</li><li>Three</li></ul>
```

Text content is automatically escaped:

```nix
[ "p" "<script>alert('xss')</script>" ]
# <p>&lt;script&gt;alert('xss')&lt;/script&gt;</p>
```

### Raw HTML and Comments

For trusted HTML that shouldn't be escaped:

```nix
[ "div" (raw "<strong>Already formatted</strong>") ]
# <div><strong>Already formatted</strong></div>
```

For HTML comments:

```nix
[ "div" (comment "TODO: refactor")
  [ "p" "Content" ] ]
# <div><!-- TODO: refactor --><p>Content</p></div>
```

### Void Elements

Self-closing tags work as expected:

```nix
[ "img" { src = "photo.jpg"; alt = "A photo"; } ]
# <img alt="A photo" src="photo.jpg">

[ "meta" { charset = "utf-8"; } ]
# <meta charset="utf-8">
```

## API

Four functions. That's the entire public interface.

| Function | Description |
|----------|-------------|
| `render` | Render to minified HTML |
| `renderPretty` | Render to indented HTML (2-space indent) |
| `raw` | Mark a string as trusted, unescaped HTML |
| `comment` | Create an HTML comment node |

## A Real Example: Blog Generator

```nix
{ pkgs, niccup }:
let
  h = niccup.lib;

  posts = [
    { slug = "hello"; title = "Hello World"; body = "Welcome!"; }
    { slug = "update"; title = "An Update"; body = "More content here."; }
  ];

  layout = { title, content }: h.renderPretty [
    "html" { lang = "en"; }
    [ "head"
      [ "meta" { charset = "utf-8"; } ]
      [ "meta" { name = "viewport"; content = "width=device-width"; } ]
      [ "title" title ]
    ]
    [ "body"
      [ "nav" (map (p: [ "a" { href = "/${p.slug}.html"; } p.title ]) posts) ]
      [ "main" content ]
      [ "footer" "Generated with niccup" ]
    ]
  ];

  renderPost = post: layout {
    title = post.title;
    content = [ "article" [ "h1" post.title ] [ "p" post.body ] ];
  };

in pkgs.runCommand "blog" {} ''
  mkdir -p $out
  ${builtins.concatStringsSep "\n" (map (p: ''
    cat > $out/${p.slug}.html << 'EOF'
    ${renderPost p}
    EOF
  '') posts)}
''
```

This produces a complete static site as a Nix derivation. Add a post to the list, rebuild, done.

## Limitations

Being upfront about what niccup doesn't do:

- **Attribute order is alphabetical.** Nix attribute sets have no insertion order; `builtins.attrNames` returns keys sorted lexicographically. You cannot control attribute order in the output.

- **One-level flattening only.** `[ "ul" (map ...) ]` works because `map` returns a list that gets flattened. Deeper nesting like `[ "ul" [ [ [ "li" "x" ] ] ] ]` won't flatten further, you'll get nested elements, not flattened children.

- **Eager evaluation.** The entire tree is evaluated before rendering. For the static site generation use case, this is fine. If you're generating gigabytes of HTML, this isn't your tool.

- **No streaming.** Output is a single string. Again, fine for static sites; not designed for chunked HTTP responses.

## Why Hiccup?

The Hiccup format originated in Clojure and has been battle-tested for over a decade. It maps naturally to Nix because both languages treat data structures as first-class citizens. The syntax is minimal, just lists and attribute sets, and composes with existing Nix idioms without friction.

The name "niccup" is a portmanteau: **Ni**x + Hic**cup**.

## Source

The entire implementation is ~120 lines of pure Nix with no external dependencies. The code, tests, and additional examples are available at:

**[github.com/embedding-shapes/niccup](https://github.com/embedding-shapes/niccup)**

MIT licensed.
