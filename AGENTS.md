# Dotfiles — CachyOS + niri + DMS + fish

Repo manual (sin stow/chezmoi). Los archivos aquí son copia de `~/.config`.

## Mapa repo -> sistema

- `niri/config.kdl` -> `~/.config/niri/config.kdl`
- `niri/cfg/*.kdl` -> `~/.config/niri/cfg/` (animation, autostart, keybinds, input, display, layout, rules, misc)
- `niri/dms/*.kdl` -> `~/.config/niri/dms/` — GENERADO por DMS (`dux-shell` 2.1.1), preferir cambiar desde la UI de DMS
- `fish/config.fish`, `fish/fish_variables` -> `~/.config/fish/`
- `fish/functions/*.fish` -> `~/.config/fish/functions/`
- `DankMaterialShell/settings.json`, `clsettings.json`, `plugins.lock.json` -> `~/.config/dms/` (dux-shell >= 2.1; la ruta antigua `~/.config/DankMaterialShell/` ya no se usa)
- `systemd/user/*` -> `~/.config/systemd/user/`
- `wireplumber/wireplumber.conf.d/*.conf` -> `~/.config/wireplumber/wireplumber.conf.d/` (ajustes de audio/PipeWire, p. ej. no suspender sink Bluetooth)
- `udev/rules.d/*.rules` -> `/etc/udev/rules.d/` — requiere root; NO copiar con `cp` normal, usar `sudo`/`pkexec` (ver ejemplo abajo)
- `modprobe/*.conf` -> `/etc/modprobe.d/` — requiere root (parámetros de módulos, p. ej. `btusb`)
- `dconf/wm-preferences.ini` -> dconf, ruta `/org/gnome/desktop/wm/preferences/` — NO es un archivo de `~/.config`. Aplicar con `dconf load /org/gnome/desktop/wm/preferences/ < dconf/wm-preferences.ini`. `button-layout=':'` quita los botones de ventana (min/max/cerrar) de las apps GTK3/GTK4 (Nautilus); afecta a todas ellas, niri no lo usa.
- `firefox/userChrome.css`, `firefox/user.js` -> `~/.config/mozilla/firefox/<perfil>.default-release/` (`chrome/userChrome.css` y `user.js`) — Firefox 159+ usa la ruta XDG (`~/.config/mozilla`), no `~/.mozilla`; `user.js` activa `toolkit.legacyUserProfileCustomizations.stylesheets` y oculta los botones de ventana

Nautilus/Firefox no tienen ajuste propio para ocultar botones y niri no dibuja
títulos. En GTK4 no se pueden ocultar widgets por CSS (`display`/`visibility` no
existen) y `~/.config/gtk-4.0/settings.ini` se ignora: GTK lee
`org.gnome.desktop.wm.preferences button-layout`. Firefox se hace con
userChrome.css. Cerrar ventanas sin botón: `Mod+Q` (niri), `Ctrl+Shift+W`
(Firefox), `Ctrl+W` (Nautilus).

`config.kdl` principal solo tiene `include`. No aplanar los includes.

Los `include` de `dms/*` van **después** de `cfg/*`, así que DMS gana en valores
escalares repetidos (gaps, geometría de bordes, colores...). No dupliques esos
ajustes en `cfg/`: se cambian desde la UI de DMS.

DMS arranca con `dms.service` (`systemctl --user`), enlazado en
`niri.service.wants/`. No pongas `spawn-at-startup "dms run"` en
`niri/cfg/autostart.kdl`: arrancaría dos instancias. Noctalia no forma parte del
setup; si está instalado no debe autostartearse.

DMS 2.1 genera un set completo de keybinds en `dms/binds.kdl`. Ese include está
comentado en `config.kdl` a propósito: si se activa, pisa `cfg/keybinds.kdl`.
Para gestionar keybinds desde la UI de DMS, descomenta el include y borra los
binds equivalentes de `cfg/keybinds.kdl`.

## Login (greeter)

El display manager es **greetd** con **DMS Greeter** (`dux-greeter-bin`), no SDDM:

- `display-manager.service` -> `/usr/lib/systemd/system/greetd.service`
- `sddm.service` está `masked` (no borrado, por si hay que volver)
- `/etc/greetd/config.toml` ejecuta:
  `dms-greeter --command niri --cache-dir /var/cache/dms-greeter -C /etc/greetd/niri/config.kdl`
- `/etc/greetd/niri/{config.kdl,dms.kdl}` los genera `dms-greeter sync` (no editar a mano)
- Tras cambiar tema/fuente/fondo en DMS: `dms-greeter sync` (pide sudo) y el slot
  `users/fabian` es *live* (sigue a `~/.config/dms` sin re-sync)
- Tras añadir el usuario al grupo `greeter` hace falta cerrar sesión para que aplique
- Revertir a SDDM: `sudo systemctl unmask sddm && sudo systemctl enable sddm && sudo systemctl disable greetd`
  (script: `~/dotfiles-backup-20261108_210456/greeter/revert-to-sddm.sh`)

## Reglas duras

- No romper arranque de niri: toda edición KDL debe pasar `niri validate`.
- Nunca ejecutar `niri msg action quit`, `pkill niri`, ni reiniciar sesión sin confirmación explícita.
- No editar `niri/dms/*` a mano salvo que DMS no lo cubra; si se edita, anotarlo en el commit.
- fish: validar con `fish -n <archivo>`. No usar sintaxis bash/zsh en `config.fish`.
- `config.fish` hace `source /usr/share/cachyos-fish-config/cachyos-config.fish` — no quitar esa línea sin reemplazo.
- No commitear secretos, tokens, `*.backup*`, cachés ni `fish_variables` con rutas de máquina si contienen datos sensibles. Revisar `git diff` antes de commit.
- CachyOS = Arch-base: usar `pacman` / `paru`, `systemctl --user`. Nunca `apt`, `dnf`.
- wireplumber: tras editar un `.conf`, `systemctl --user restart wireplumber` **corta el audio ~1 s** y puede desconectar dispositivos Bluetooth. Verificar con `journalctl --user -u wireplumber` que no haya errores de config.
- udev: las reglas van a `/etc/` (root). Validar sintaxis con `udevadm test /sys/<dispositivo>` — una clave de match inválida hace que udev **descarte la regla entera** en silencio (el log solo dice `Invalid key`).
- udev, caso real: `DEVTYPE` es una propiedad, no un atributo sysfs. Hay que usar `ENV{DEVTYPE}=="usb_device"`; con `ATTR{DEVTYPE}` la regla nunca matchea y no verás errores. Comprobar que el `udevadm test` muestre la escritura del `ATTR{...}` esperado.

## Flujo de trabajo

1. Editar en `~/.config/...`, probar, luego copiar al repo — o al revés, pero nunca dejarlos divergentes sin commit.
2. Validar:
  - `niri validate`
  - `fish -n ~/dotfiles/fish/config.fish`
  - `python3 -m json.tool ~/dotfiles/DankMaterialShell/settings.json > /dev/null`
  - WirePlumber: no hay validador; reiniciar el servicio y revisar el journal por errores.
3. Copiar al sistema (ejemplo):
  `cp ~/dotfiles/niri/config.kdl ~/.config/niri/config.kdl`
  `cp ~/dotfiles/niri/cfg/* ~/.config/niri/cfg/`
  `cp ~/dotfiles/DankMaterialShell/*.json ~/.config/dms/` (dux-shell >= 2.1)
  `cp ~/dotfiles/systemd/user/* ~/.config/systemd/user/ && systemctl --user daemon-reload`
  `cp ~/dotfiles/wireplumber/wireplumber.conf.d/*.conf ~/.config/wireplumber/wireplumber.conf.d/`
  `sudo cp ~/dotfiles/udev/rules.d/*.rules /etc/udev/rules.d/ && sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=usb --action=change`
  `sudo cp ~/dotfiles/modprobe/*.conf /etc/modprobe.d/` (los parámetros de módulo se aplican al recargar el módulo o al reiniciar)
4. Recargar sin cerrar sesión: `niri msg action load-config-file` o `niri msg action reload-config` según versión. Si falla, `niri validate` y revertir.
5. Commit con mensaje claro: `niri: ...`, `fish: ...`, `dms: ...`, `wireplumber: ...`, `udev: ...`.

## Dependencias

- `niri`, `quickshell`, DMS (`dux-shell` 2.1 / Dux Shell), `fish`, `paru`
- Fuente `Comfortaa` (`ttf-comfortaa`), `arch-audit` (lo usa `audit-packages`), agentes polkit para operaciones root
- Temas referenciados en settings: iconos `Tela-circle-blue`, cursor `Bibata-Modern-Classic`, `fontScale` global `0.9`, `controlCenterIconScale` `1.0`, barra con `iconScale` `1.22`
- Sonido de notificaciones DMS: `useSystemSoundTheme=true` (tema `freedesktop`: la notificación mapea a `dialog-information.oga`, 47 ms, muy bajo).
- Bluetooth: el adaptador es un Intel 7260 (`8087:07dc`) con ROM de 2013; su firmware no cumple el flow-control de A2DP (`Missing completion reports`). La regla udev de `udev/` y `modprobe/btusb-no-autosuspend.conf` le desactivan el autosuspend USB, que agravaba los microcortes. Al volver de suspensión el adaptador se reenumera (`hci0` -> `hci1`), recarga firmware y el transporte A2DP se corta: es una limitación del hardware.
