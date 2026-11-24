# Dotfiles — CachyOS + niri + DMS + fish

Repo manual (sin stow/chezmoi). Los archivos aquí son copia de `~/.config`.

## Mapa repo -> sistema

- `niri/config.kdl` -> `~/.config/niri/config.kdl`
- `niri/cfg/*.kdl` -> `~/.config/niri/cfg/` (animation, autostart, keybinds, input, display, layout, rules, misc)
- `niri/dms/*.kdl` -> `~/.config/niri/dms/` — GENERADO por DMS (`dux-shell` 2.1.1), preferir cambiar desde la UI de DMS
- `fish/config.fish`, `fish/fish_variables` -> `~/.config/fish/`
- `fish/functions/*.fish` -> `~/.config/fish/functions/`
- `DankMaterialShell/settings.json`, `clsettings.json`, `plugins.lock.json` -> `~/.config/dms/` (dux-shell >= 2.1; la ruta antigua `~/.config/DankMaterialShell/` ya no se usa)
- `DankMaterialShell/i18n/*` -> `~/.config/dms/i18n/` — override de traducción al español: `es.json` completo (PR #4203, adaptado a es-419), `DCommon-es.json` y `dms-es-apply.sh`, que se ejecuta como `ExecStartPre` de `dms.service` vía `systemd/user/dms.service.d/i18n-es.conf`. Parchea la extracción de `$XDG_RUNTIME_DIR/dms-shell/<rev>` antes de arrancar el shell; se reaplica solo tras reinicios/actualizaciones.
- `dux-files/i18n/*` -> `~/.config/dux-files/i18n/` — override de traducción es-419 de Dux Files (`dfiles`, paquete `dux-files-bin`): `duxfiles-es.json` (658/658 términos propios) y `dfiles-es-apply.sh`, que corre como **`ExecStartPost`** (con `--wait`) de `dfiles.service` vía `systemd/user/dfiles.service.d/i18n-es.conf`. No es `ExecStartPre` como DMS porque `dfiles` **reescribe** su extracción de `$XDG_RUNTIME_DIR/dfiles-shell/<rev>` en cada arranque; el script espera al proceso `qs -p <rev>` y parchea antes de que QML cargue las traducciones. Reutiliza `~/.config/dms/i18n/DCommon-es.json`. Requiere `dfiles.service` habilitado y enlazado en `niri.service.wants/`.
- `dms-greeter/i18n/*` + `dms-greeter/install-es.sh` -> `/etc/greetd/i18n/` — override de traducción es-419 del **login** (DMS Greeter, paquete `dux-greeter-bin`). `es.json` cubre las 25 cadenas propias del greeter y `DCommon-es.json` las 130 de los widgets comunes (el original trae 4/25 y 52/130). Se instala con `sudo dms-greeter/install-es.sh`, que deja `systemd/system/greetd.service.d/i18n-es.conf` con dos ganchos: `ExecStartPre` parchea las revisiones ya extraídas y `ExecStartPost --wait` espera al proceso `qs -p <rev>` para parchear una revisión **nueva** en el mismo arranque (el cache se reextrae al cambiar de versión). También parchea al instante la revisión ya extraída de `/var/cache/dms-greeter/.cache/dms-greeter-shell/<rev>/`. El cache se reutiliza entre arranques, así que el parche sobrevive reinicios y `dms-greeter sync`.
- `systemd/user/*` -> `~/.config/systemd/user/`
- `systemd/system/*` -> `/etc/systemd/system/` — requiere root; unidades y drop-ins de sistema (p. ej. `var-cache.mount.d/lazy-unmount.conf`, `greetd.service.d/i18n-es.conf`)
- `xdg-desktop-portal/niri-portals.conf` -> `~/.config/xdg-desktop-portal/niri-portals.conf` — override **mínimo**: solo fija `org.freedesktop.impl.portal.FileChooser=dfiles;gnome;gtk;`. El resto de interfaces (ScreenCast para compartir pantalla, etc.) se hereda de `/usr/share/xdg-desktop-portal/niri-portals.conf`; no copiar el archivo completo del sistema, o se congelan los defaults de niri. Aplicar con `cp` y `systemctl --user restart xdg-desktop-portal` (en la sesión gráfica); validar con `XDG_CURRENT_DESKTOP=niri dfiles portal status`.
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

DMS 2.1 genera un set completo de keybinds en `dms/binds.kdl`, incluido en
`config.kdl` y con prioridad sobre `cfg/keybinds.kdl`. `cfg/keybinds.kdl` solo
conserva los binds propios que DMS no genera (apps, screenshots, mover a
workspaces...). Si cambias keybinds desde la UI de DMS, no dupliques en `cfg/`
los que ya genere `dms/binds.kdl`.

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
- Traducción del login al español: ver `dms-greeter/i18n/*` en el mapa. El greeter **no** usa
  `~/.config/dms/i18n`; su UI va embebida y se parchea en `/var/cache/dms-greeter/.cache/dms-greeter-shell/<rev>/`
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
- dux-files: `dfiles` **reescribe** su extracción en `$XDG_RUNTIME_DIR/dfiles-shell/<rev>` en cada arranque, así que un `es.json` copiado antes de lanzarlo se pierde. El parche va como `ExecStartPost=... --wait` (espera a `qs -p <rev>`) y requiere `dfiles.service` habilitado; no lo cambies a `ExecStartPre`. Tras editar `duxfiles-es.json` o el script: copiar a `~/.config/dux-files/i18n/` y `systemctl --user restart dfiles`.

## Flujo de trabajo

1. Editar en `~/.config/...`, probar, luego copiar al repo — o al revés, pero nunca dejarlos divergentes sin commit.
2. Validar:
  - `niri validate`
  - `fish -n ~/dotfiles/fish/config.fish`
  - `python3 -m json.tool ~/dotfiles/DankMaterialShell/settings.json > /dev/null`
  - `bash -n ~/dotfiles/dux-files/i18n/dfiles-es-apply.sh`
  - `python3 -m json.tool ~/dotfiles/dux-files/i18n/duxfiles-es.json > /dev/null`
  - WirePlumber: no hay validador; reiniciar el servicio y revisar el journal por errores.
3. Copiar al sistema (ejemplo):
  `cp ~/dotfiles/niri/config.kdl ~/.config/niri/config.kdl`
  `cp ~/dotfiles/niri/cfg/* ~/.config/niri/cfg/`
  `cp ~/dotfiles/DankMaterialShell/*.json ~/.config/dms/` (dux-shell >= 2.1)
  `cp -r ~/dotfiles/DankMaterialShell/i18n ~/.config/dms/ && chmod +x ~/.config/dms/i18n/dms-es-apply.sh`
  `cp -r ~/dotfiles/dux-files/i18n ~/.config/dux-files/ && chmod +x ~/.config/dux-files/i18n/dfiles-es-apply.sh && systemctl --user restart dfiles`
  `cp ~/dotfiles/systemd/user/* ~/.config/systemd/user/ && systemctl --user daemon-reload`
  `sudo cp -r ~/dotfiles/systemd/system/* /etc/systemd/system/ && sudo systemctl daemon-reload`
  `cp ~/dotfiles/wireplumber/wireplumber.conf.d/*.conf ~/.config/wireplumber/wireplumber.conf.d/`
  `sudo cp ~/dotfiles/udev/rules.d/*.rules /etc/udev/rules.d/ && sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=usb --action=change`
  `sudo cp ~/dotfiles/modprobe/*.conf /etc/modprobe.d/` (los parámetros de módulo se aplican al recargar el módulo o al reiniciar)
4. Recargar sin cerrar sesión: `niri msg action load-config-file` o `niri msg action reload-config` según versión. Si falla, `niri validate` y revertir.
5. Commit con mensaje claro: `niri: ...`, `fish: ...`, `dms: ...`, `dux-files: ...`, `wireplumber: ...`, `udev: ...`.

## Dependencias

- `niri`, `quickshell`, DMS (`dux-shell` 2.1 / Dux Shell), `fish`, `paru`
- Fuente `Comfortaa` (`ttf-comfortaa`), `arch-audit` (lo usa `audit-packages`), agentes polkit para operaciones root
- Temas referenciados en settings: iconos `Tela-circle-blue`, cursor `Bibata-Modern-Classic`, `fontScale` global `0.9`, `controlCenterIconScale` `1.0`, barra con `iconScale` `1.22`
- Sonido de notificaciones DMS: `useSystemSoundTheme=true` (tema `freedesktop`: la notificación mapea a `dialog-information.oga`, 47 ms, muy bajo).
- Nautilus queda instalado solo como dependencia dura de `xdg-desktop-portal-gnome` (que aporta `ScreenCast`/compartir pantalla y es requerido por niri); no debe ser predeterminado ni aparecer en `mimeapps.list` como gestor de archivos. El gestor y el diálogo de archivos del portal son `dfiles` (`dev.duxlabs.files.desktop`).
- `/var/cache` es un subvolumen btrfs aparte en `/etc/fstab`. Al apagar, el `plymouthd` del splash de apagado (`plymouth-reboot`/`plymouth-poweroff`) carga la fuente del tema `cachyos-bootanimation` (`Font=Inter`) vía Pango -> fontconfig, y fontconfig mapea `/var/cache/fontconfig/*.cache-12`; ese mmap hace que `umount` falle con EBUSY y salga `Failed unmounting /var/cache`. No es un fallo real (systemd-shutdown lo desmonta después), pero se silencia con `LazyUnmount=yes` en `systemd/system/var-cache.mount.d/lazy-unmount.conf`. No es Proton VPN ni un proceso con fds abiertos.
- Bluetooth: el adaptador es un Intel 7260 (`8087:07dc`) con ROM de 2013; su firmware no cumple el flow-control de A2DP (`Missing completion reports`). La regla udev de `udev/` y `modprobe/btusb-no-autosuspend.conf` le desactivan el autosuspend USB, que agravaba los microcortes. Al volver de suspensión el adaptador se reenumera (`hci0` -> `hci1`), recarga firmware y el transporte A2DP se corta: es una limitación del hardware.
