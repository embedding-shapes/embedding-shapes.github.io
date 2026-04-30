---
title: How to Disable Firefox's Emoji Picker
date: 2026-04-30
slug: how-to-disable-firefoxs-emoji-picker
---

Annoyingly enough, Mozilla decided to add a emoji picker to Firefox 150, which fair enough, probably some people like, but they did it by using the shortcut of `Ctrl + .` (Control + Dot), which also happens to be the exact same shortcut 1Password uses by default, and has been using for as long as I can remember!

On GNOME we already have a global shortcut for some emoji picker, I think it's `Super + ,` or something, and besides, I don't really write any emojis in anything I use a browser for anyways, so off we go to disable it so we can properly use 1Password again.

## How to disable the shortcut

Easy peasy:

1. Open `about:config` in Firefox
2. Search for `widget.gtk.native-emoji-dialog`
3. Set it to `false`
4. Restart Firefox if `Ctrl + .` does not immediately work

For me it worked without restarting, YMMV
