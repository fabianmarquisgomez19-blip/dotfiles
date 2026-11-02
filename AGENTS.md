# Dotfiles — CachyOS + niri + DMS + fish

Repo manual (sin stow/chezmoi). Los archivos aquí son copia de `~/.config`.

## Mapa repo -> sistema

- `niri/config.kdl` -> `~/.config/niri/config.kdl`
- `niri/cfg/*.kdl` -> `~/.config/niri/cfg/` (animation, autostart, keybinds, input, display, layout, rules, misc)
- `niri/dms/*.kdl` -> `~/.config/niri/dms/` — GENERADO por DMS (paquete `dms-shell` 2.0, "Dux Shell"), preferir cambiar desde la UI de DMS
- `fish/config.fish`, `fish/fish_variables` -> `~/.config/fish/`
- `DankMaterialShell/settings.json`, `clsettings.json` -> `~/.config/DankMaterialShell/`
- `wireplumber/wireplumber.conf.d/*.conf` -> `~/.config/wireplumber/wireplumber.conf.d/` (ajustes de audio/PipeWire, p. ej. no suspender sink Bluetooth)
- `udev/rules.d/*.rules` -> `/etc/udev/rules.d/` — requiere root; NO copiar con `cp` normal, usar `sudo`/`pkexec` (ver ejemplo abajo)
- `modprobe/*.conf` -> `/etc/modprobe.d/` — requiere root (parámetros de módulos, p. ej. `btusb`)

`config.kdl` principal solo tiene `include`. No aplanar los includes.

Los `include` de `dms/*` van **después** de `cfg/*`, así que DMS gana en valores
escalares repetidos (gaps, geometría de bordes, colores...). No dupliques esos
ajustes en `cfg/`: se cambian desde la UI de DMS.

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
  `cp ~/dotfiles/wireplumber/wireplumber.conf.d/*.conf ~/.config/wireplumber/wireplumber.conf.d/`
  `sudo cp ~/dotfiles/udev/rules.d/*.rules /etc/udev/rules.d/ && sudo udevadm control --reload-rules && sudo udevadm trigger --subsystem-match=usb --action=change`
  `sudo cp ~/dotfiles/modprobe/*.conf /etc/modprobe.d/` (los parámetros de módulo se aplican al recargar el módulo o al reiniciar)
4. Recargar sin cerrar sesión: `niri msg action load-config-file` o `niri msg action reload-config` según versión. Si falla, `niri validate` y revertir.
5. Commit con mensaje claro: `niri: ...`, `fish: ...`, `dms: ...`, `wireplumber: ...`, `udev: ...`.

## Dependencias

- `niri`, `quickshell`, DMS (`dms-shell` 2.0 / Dux Shell), `fish`, `paru`
- Temas referenciados en settings: iconos `Tela-circle-blue`, cursor `Bibata-Modern-Classic`, `fontScale` global `0.9`, `controlCenterIconScale` `1.0`, barra con `iconScale` `1.22`
- Sonido de notificaciones DMS: usa los sonidos incluidos (`useSystemSoundTheme=false`). El tema `freedesktop` mapea la notificación a `dialog-information.oga` (47 ms, muy bajo).
- Bluetooth: el adaptador es un Intel 7260 (`8087:07dc`) con ROM de 2013; su firmware no cumple el flow-control de A2DP (`Missing completion reports`). La regla udev de `udev/` y `modprobe/btusb-no-autosuspend.conf` le desactivan el autosuspend USB, que agravaba los microcortes. Al volver de suspensión el adaptador se reenumera (`hci0` -> `hci1`), recarga firmware y el transporte A2DP se corta: es una limitación del hardware.
