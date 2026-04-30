---
title: Cómo desactivar el selector de emojis de Firefox
date: 2026-04-30
slug: como-desactivar-el-selector-de-emojis-de-firefox
---

Para colmo, Mozilla decidió añadir un selector de emojis en Firefox 150, que vale, seguramente a algunas personas les guste, pero lo hicieron usando el atajo `Ctrl + .` (Control + punto), que además resulta ser exactamente el mismo atajo que 1Password usa por defecto, ¡y que lleva usando desde que tengo memoria!

En GNOME ya tenemos un atajo global para algún selector de emojis, creo que es `Super + ,` o algo así, y además, la verdad es que no suelo escribir emojis en nada de lo que hago en el navegador, así que toca desactivarlo para poder volver a usar 1Password como es debido.

## Cómo desactivar el atajo

Facilísimo:

1. Abre `about:config` en Firefox
2. Busca `widget.gtk.native-emoji-dialog`
3. Cámbialo a `false`
4. Reinicia Firefox si `Ctrl + .` no empieza a funcionar de inmediato

En mi caso funcionó sin reiniciar, pero puede que en el tuyo no
