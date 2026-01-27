---
title: One Human + One Agent = One Browser From Scratch
date: 2026-01-27
---

# One Human + One Agent = One Browser From Scratch

Just for the fun of it, I thought I'd embark on a week long quest to generate millions of tokens and millions lines of source code to create one basic browser that can render HTML and CSS (no JS tho), and hopefully I could use this to receive even more VC investments.

But then I remembered that I have something even better: a human brain! It is usually better than any machine at coordinating and thinking through things, so lets see if we can hack something together, one human brain and one LLM agent brain!

![Demonstration of one-agent-one-browser running with a bunch of different websites on Linux/X11](/content/one-human-one-agent-one-browser.webm)

The above might look like a simple .webm video, but it's actually a highly sophisticated and advanced browser that was super hard to build, encoded as pixels in a video file! Wowzsers.

For extra fun when building this, I set these requirements for myself and the agent:

- I have three days to build it
- Not a single 3rd party Rust library/dependency allowed
- Allowed to use anything (commonly) provided out of the box on the OS it runs on
- Should run on Windows, macOS and common Linux distributions
- Should be able to render some websites, most importantly, my own blog and Hacker News, should be easy right?
- The codebase can always compile and be built
- The codebase should be readable by a human, although code quality isn't the top concern

So with these things in mind, I set out on the journal to build a browser "from scratch". I started with something really based, being able to just render "Hello World". Then to be able to render some nested tags. Added the ability of taking screenshots so the agent could use that. Added specifications for HTML/CSS (which I think the agent never used :| ), and tried to nail down the requrements for the agent to use. Also started doing "regression" or "E2E" tests with the screenshotting feature, so we could compare to some baseline images and so on. Added the ability to click on links to just for the fun of it.

After about a day together with Codex, I had something that could via X11 and cURL, fetch and render websites when run, and the Cargo.lock is empty. It's was about 7500 lines long in total at that point, split across files with all of them under 1000 lines long (which was a stated requirement, so not a surprise).

Second day I got annoying by the tests spawning windows while I was doing other stuff, so added a --headless flag too. Did some fixes for resizing the window, various compability fixes, some performance issues and improved the font/text rendering a bunch.  Workflow was basically to pick a website, share a screenshot of the website without JavaScript, ask codex to replicate it following our instructions. Most of the time was the agent doing work by itself, and me checking in when it notifies me it was done.

Third day we made large changes, lots of new features and a bunch of new features supported. More regression tests, fixing performance issues, fixing crashes and what not. Also added scrolling because this is a mother fucking browser, it has to be able to scroll. Added some debug logs too because that'll look cool in the demonstration video below, and also added support for the back button.

At the end of the third day we also added support for macOS finally, and managed to get a window to open, and the tests to pass. Seems to work OK :) Once we had that working, we also added Windows support, basically the same process, just another platform after all.

Then the fourth day (whaaaat?) was basically polish, fixing CI for all three platforms, making it pass and finally cutting a release based on what got built in CI.

## The results after ~3 days (~70 hours)

And here it is, in all it's glory, made in ~20K lines of code and under 72 hours of total elapsed time from first commit to last:

[![Screenshot of one-agent-one-browser running on X11](/content/one-agent-one-browser-hn.png)](https://github.com/embedding-shapes/one-agent-one-browser)

> You could try compiling it yourself (zero Rust dependencies, so it's really fast :) ), or you can find binaries built on CI here:<br/><small>[https://github.com/embedding-shapes/one-agent-one-browser/releases](https://github.com/embedding-shapes/one-agent-one-browser/releases)</small>


You can clone the repository, build it and try it out for yourself. It's not great, I wouldn't even say it's good, but it works, and demonstrates that one person with one agent, can build a browser from scratch.

This is what the "lines of code" count ended up being after all was said and done, including support three OSes:

```shell
$ git rev-parse HEAD
e2556016a5aa504ecafd5577c1366854ffd0e280

$ cloc src --by-file
      72 text files.
      72 unique files.
       0 files ignored.

github.com/AlDanial/cloc v 2.06  T=0.06 s (1172.5 files/s, 373824.0 lines/s)
-----------------------------------------------------------------------------------
File                                            blank        comment           code
-----------------------------------------------------------------------------------
src/layout/flex.rs                                 96              0            994
src/layout/inline.rs                               85              0            933
src/layout/mod.rs                                  82              0            910
src/browser.rs                                     78              0            867
src/platform/macos/painter.rs                      96              0            765
src/platform/x11/cairo.rs                          77              0            713
src/platform/windows/painter.rs                    88              0            689
src/bin/render-test.rs                             87              0            666
src/style/builder.rs                               83              0            663
src/platform/windows/d2d.rs                        53              0            595
src/platform/windows/windowed.rs                   72              0            591
src/style/declarations.rs                          18              0            547
src/image.rs                                       81              0            533
src/platform/macos/windowed.rs                     80              2            519
src/net/winhttp.rs                                 61              2            500
src/platform/x11/mod.rs                            56              2            487
src/css.rs                                        103            346            423
src/html.rs                                        58              0            413
src/platform/x11/painter.rs                        48              0            407
src/platform/x11/scale.rs                          57              3            346
src/layout/table.rs                                39              1            340
src/platform/x11/xft.rs                            35              0            338
src/style/parse.rs                                 34              0            311
src/win/wic.rs                                     39              8            305
src/style/mod.rs                                   26              0            292
src/style/computer.rs                              35              0            279
src/platform/x11/xlib.rs                           32              0            278
src/layout/floats.rs                               31              0            265
src/resources.rs                                   36              0            238
src/css_media.rs                                   36              1            232
src/debug.rs                                       32              0            227
src/platform/windows/dwrite.rs                     20              0            222
src/render.rs                                      18              0            196
src/style/custom_properties.rs                     34              0            186
src/platform/windows/scale.rs                      28              0            184
src/url.rs                                         32              0            173
src/layout/helpers.rs                              12              0            172
src/net/curl.rs                                    31              0            171
src/platform/macos/svg.rs                          35              0            171
src/browser/url_loader.rs                          17              0            166
src/platform/windows/gdi.rs                        17              0            165
src/platform/windows/scaled.rs                     16              0            159
src/platform/macos/scaled.rs                       16              0            158
src/layout/svg_xml.rs                               9              0            152
src/win/com.rs                                     26              0            152
src/png.rs                                         27              0            146
src/layout/replaced.rs                             15              0            131
src/net/pool.rs                                    18              0            129
src/platform/macos/scale.rs                        17              0            124
src/style/selectors.rs                             18              0            123
src/style/length.rs                                17              0            121
src/cli.rs                                         15              0            112
src/platform/windows/headless.rs                   20              0            112
src/platform/macos/headless.rs                     19              0            109
src/bin/fetch-resource.rs                          14              0            101
src/geom.rs                                        10              0            101
src/browser/render_helpers.rs                      11              0            100
src/dom.rs                                         11              0            100
src/style/background.rs                            15              0            100
src/layout/tests.rs                                 7              0             85
src/platform/windows/d3d11.rs                      14              0             83
src/win/stream.rs                                  10              0             63
src/platform/windows/svg.rs                        13              0             54
src/main.rs                                         4              0             33
src/platform/mod.rs                                 6              0             28
src/app.rs                                          5              0             25
src/lib.rs                                          1              0             20
src/platform/windows/mod.rs                         2              0             19
src/net/mod.rs                                      4              0             16
src/platform/macos/mod.rs                           2              0             14
src/platform/windows/wstr.rs                        0              0              5
src/win/mod.rs                                      0              0              3
-----------------------------------------------------------------------------------
SUM:                                             2440            365          20150
-----------------------------------------------------------------------------------
```

## Takeaways

- One human using one agent seems far more effective than one human using thousands of agents
- One agent can work on a single codebase for hours, making real progress on ambitious projects
- This could probably scale to multiple humans too, each equiped with their own agent, imagine what we could achieve!
- Sometimes slower is faster and also better
- The human who drives the agent might matter more than how the agents work and are setup, the judge is still out on this one

If one person with one agent can produce equal or better results than "hundreds of agents for weeks", then the answer to the question: "Can we scale autonomous coding by throwing more agents at a problem?", probably has a more pessimistic answer than some expected. 
