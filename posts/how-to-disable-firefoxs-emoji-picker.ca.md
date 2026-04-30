---
title: Com desactivar el selector d’emojis del Firefox
date: 2026-04-30
slug: com-desactivar-el-selector-demojis-del-firefox
---

És força empipador que Mozilla decidís afegir un selector d’emojis al Firefox 150, cosa que, d’acord, segurament hi ha gent a qui agrada, però ho van fer fent servir la drecera `Ctrl + .` (Control + punt), que resulta que és exactament la mateixa drecera que l’1Password fa servir per defecte, i que fa servir des que tinc memòria!

Al GNOME ja tenim una drecera global per a algun selector d’emojis, crec que és `Super + ,` o alguna cosa així, i a més, de totes maneres, no és que escrigui gaires emojis en res del que faig servir amb el navegador, així que toca desactivar-la per poder tornar a fer servir l’1Password com cal.

## Com desactivar la drecera

Bufar i fer ampolles:

1. Obre `about:config` al Firefox
2. Cerca `widget.gtk.native-emoji-dialog`
3. Canvia’n el valor a false
4. Reinicia el Firefox si `Ctrl + .` no funciona immediatament

A mi em va funcionar sense reiniciar, però pot ser que a tu no
