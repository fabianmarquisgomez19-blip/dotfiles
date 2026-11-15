# Traducción al español (es-419) para Dux Files

`dux-files` 2.1.2 (`dux-files-bin`, binario `dfiles`) embebe su UI de Quickshell
y solo trae `de, hu, nl, uk, zh_CN, zh_TW`: **no hay `es.json`**, así que toda
la interfaz propia de Files sale en inglés. Además su `DCommon` (widgets
compartidos con DMS) trae el español al 40 %.

Este directorio cubre las dos cosas:

- `duxfiles-es.json`: traducción de la UI de Files, **100 %** (658/658
  términos), con el formato `contexto → término → traducción` de los exports de
  POEditor. Base: `translations/en.json` de la revisión instalada, traducida a
  español latinoamericano (es-419) con el mismo glosario que
  `DankMaterialShell/i18n/es.json` (carpeta, archivo, papelera, pestaña, panel,
  unidad, marcador, presionar, mouse...).
- `dfiles-es-apply.sh`: aplica ese archivo sobre la UI embebida.
- `DCommon` **no se duplica**: el script reutiliza
  `~/.config/dms/i18n/DCommon-es.json`, que cubre los mismos 130 contextos y
  claves que el `DCommon` que embarca Files.

## Cómo se aplica

`dfiles` extrae su UI en `$XDG_RUNTIME_DIR/dfiles-shell/<rev>/` y la
**reescribe en cada arranque** (a diferencia de `dms-shell`, que reutiliza la
extracción). Un parche escrito antes de arrancar se pierde cuando el proceso
extrae el árbol de nuevo.

Por eso el script corre como **`ExecStartPost`** (no `ExecStartPre`) con
`--wait`:

1. espera a que termine la extracción; la señal fiable es el proceso
   `qs -p <rev>`, que dfiles lanza justo después de extraer;
2. escribe `translations/poexports/es.json` y
   `DCommon/translations/poexports/es.json` en esa revisión;
3. QML carga las traducciones ~1 s después, así que el parche llega antes de
   que la UI se dibuje.

El drop-in `systemd/user/dfiles.service.d/i18n-es.conf` hace que se ejecute en
cada arranque de `dfiles.service`. Por eso el servicio debe estar **habilitado**
(arranca en el login y queda residente; también es lo que recomienda upstream
para que las ventanas abran al instante). Sin el servicio, Files arranca de
forma perezosa desde `dfiles`/`dfiles toggle` y el parche no se aplicaría.

## Instalación

```fish
mkdir -p ~/.config/dux-files
cp -r ~/dotfiles/dux-files/i18n ~/.config/dux-files/
chmod +x ~/.config/dux-files/i18n/dfiles-es-apply.sh

mkdir -p ~/.config/systemd/user/dfiles.service.d
cp ~/dotfiles/systemd/user/dfiles.service.d/i18n-es.conf ~/.config/systemd/user/dfiles.service.d/

mkdir -p ~/.config/systemd/user/niri.service.wants
ln -sf /usr/lib/systemd/user/dfiles.service ~/.config/systemd/user/niri.service.wants/dfiles.service

systemctl --user daemon-reload
systemctl --user enable --now dfiles.service
```

Si `~/.config/dms/i18n/DCommon-es.json` no existe (override de DMS sin
instalar), copia `DCommon-es.json` a `~/.config/dux-files/i18n/`; el script lo
usa como respaldo.

## Reaplicar a mano

```fish
~/.config/dux-files/i18n/dfiles-es-apply.sh
systemctl --user restart dfiles
```

El script solo actúa sobre la extracción viva; al reiniciar, `ExecStartPost`
volverá a aplicar el override automáticamente.

## Comprobar que está activo

```fish
journalctl --user -u dfiles.service -b --no-pager | grep -E "dfiles-es|Using locale|Loaded translations"
```

Debe aparecer `dfiles-es: aplicado duxfiles-es.json ...`,
`Using locale 'es' from file:///run/user/<uid>/dfiles-shell/<rev>/translations/poexports/es.json`
y `Loaded translations for 'es' (658 contexts)`.

Con `LANG=es_VE.UTF-8` y Ajustes → Idioma en «Predeterminado del sistema»,
Files resuelve el idioma a `es`. Si tienes fijado otro idioma en Ajustes,
cámbialo a «Español».

## Revertir

```fish
rm ~/.config/systemd/user/dfiles.service.d/i18n-es.conf
rm -r ~/.config/dux-files/i18n
systemctl --user daemon-reload
systemctl --user restart dfiles
# opcional: volver al arranque perezoso
systemctl --user disable --now dfiles.service
rm ~/.config/systemd/user/niri.service.wants/dfiles.service
```

Sin el drop-in, Files vuelve al inglés (no hay traducción oficial de es).

## Notas

- No se toca el binario ni se copian los ~40 MB de la UI: solo se añade un
  JSON de ~60 KB sobre la extracción temporal.
- Tras actualizar `dux-files`, la revisión extraída cambia y el parche se
  reaplica solo en el siguiente arranque: no hay paso manual.
- El detector de «extracción terminada» usa `pgrep -f "qs -p <rev>"`. Si una
  versión futura cambia el nombre del proceso, hay que ajustar el script.
- Upstream no acepta PRs de traducción: el proyecto POEditor de `dux-files` es
  independiente del de Dux Shell. Si el español entra en mainline, borra este
  override.
- `dux-calendar` y `dms-greeter` tampoco tienen `es`; se puede repetir el mismo
  patrón si hace falta.
