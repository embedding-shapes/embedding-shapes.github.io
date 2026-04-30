---
title: Så här inaktiverar du Firefoxs emojiväljare
date: 2026-04-30
slug: sa-har-inaktiverar-du-firefoxs-emojivaljare
---

Irriterande nog bestämde sig Mozilla för att lägga till en inbyggd emojiväljare i Firefox 150, vilket i och för sig säkert vissa uppskattar, men de gjorde det genom att använda kortkommandot `Ctrl + .` (Control + punkt), vilket dessutom råkar vara exakt samma kortkommando som 1Password använder som standard, och har använt så länge jag kan minnas!

I GNOME har vi redan ett globalt kortkommando för någon form av emojiväljare, jag tror att det är `Super + ,` eller något åt det hållet, och dessutom skriver jag egentligen inte emojis i något av det jag använder en webbläsare till ändå, så nu inaktiverar vi det så att vi kan använda 1Password ordentligt igen.

## Så här inaktiverar du kortkommandot

Busenkelt:

1. Öppna `about:config` i Firefox
2. Sök efter `widget.gtk.native-emoji-dialog`
3. Sätt det till `false`
4. Starta om Firefox om `Ctrl + .` inte fungerar direkt

För mig fungerade det utan omstart, men det kan variera
