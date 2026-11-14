# Traducción completa al español para DMS

DMS 2.1.2 trae el `es.json` oficial al **47%** (1636/3484 cadenas). Por eso,
aunque el locale sea `es_VE.UTF-8` y DMS cargue `es`, buena parte de la UI
sigue en inglés. `DCommon` (navegador de archivos, menú de energía) está al 40%.

Este directorio sobreescribe esas traducciones con un archivo completo:

- `es.json`: traducción de la UI principal, **100%** (3484/3484).
  Base: [PR #4203](https://github.com/duxlabs-dev/dux-shell/pull/4203)
  (cerrado porque upstream solo acepta cambios vía POEditor), adaptada de
  español de España a español latino:
  `ratón → mouse`, `vídeo → video`, `ordenador → computadora`,
  `pulsar/pulsado/pulsación → presionar/presionado/presión`,
  `datos móviles → datos celulares`. Se conservan términos estándar de
  es-419 como `Ajustes` o `Fondo de pantalla`.
- `DCommon-es.json`: traducción de los widgets comunes, **100%** (130/130).
- `dms-es-apply.sh`: copia ambos archivos sobre la UI embebida de DMS.

## Cómo se aplica

`dms` extrae su UI embebida en `$XDG_RUNTIME_DIR/dms-shell/<rev>/` y la
reutiliza mientras el archivo `.dankrev` coincida (es de solo lectura, pero el
usuario es el propietario). El script:

1. Ejecuta `dms doctor`, que fuerza esa extracción si todavía no existe.
2. Reemplaza `translations/poexports/es.json` y
   `DCommon/translations/poexports/es.json` en cada revisión extraída.

El drop-in `systemd/user/dms.service.d/i18n-es.conf` lo ejecuta como
`ExecStartPre` de `dms.service`, **antes** de que arranque el shell. Así no hay
que reiniciar DMS después de cada login y el parche se reaplica solo tras
actualizaciones de DMS (nueva revisión → nueva extracción → nuevo parche).

## Instalación

```fish
cp -r ~/dotfiles/DankMaterialShell/i18n ~/.config/dms/
chmod +x ~/.config/dms/i18n/dms-es-apply.sh
mkdir -p ~/.config/systemd/user/dms.service.d
cp ~/dotfiles/systemd/user/dms.service.d/i18n-es.conf ~/.config/systemd/user/dms.service.d/
systemctl --user daemon-reload
systemctl --user restart dms
```

## Reaplicar a mano (sin reiniciar DMS)

```fish
~/.config/dms/i18n/dms-es-apply.sh
systemctl --user restart dms
```

## Revertir

```fish
rm ~/.config/systemd/user/dms.service.d/i18n-es.conf
rm -r ~/.config/dms/i18n
systemctl --user daemon-reload
systemctl --user restart dms
```

Sin el drop-in, DMS vuelve a usar la traducción oficial (47%).

## Notas

- No se toca el binario ni se copian los ~48 MB de la UI: solo se parchea el
  `es.json` de la extracción temporal.
- El greeter (`dms-greeter`) es otra instalación (`/var/cache/dms-greeter`,
  requiere root) y no está cubierto por este override.
- Si upstream completa el español en POEditor, borra este override para
  volver a la traducción oficial.
- Para contribuir la traducción: <https://poeditor.com/join/project/kyeCPTpmJM>
  (DMS exige ≥80% para incorporar un idioma a mainline).
