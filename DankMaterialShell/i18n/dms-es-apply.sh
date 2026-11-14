#!/usr/bin/env bash
# Aplica la traducción completa al español sobre la UI embebida de DMS.
# Pensado como ExecStartPre= de dms.service: fuerza la extracción de la UI
# embebida en $XDG_RUNTIME_DIR/dms-shell/<rev> y reemplaza las traducciones
# es.json antes de que arranque el shell.
#
# El override vive en ~/.config/dms/i18n/ (copia de DankMaterialShell/i18n/).
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
src_dir="$config_home/dms/i18n"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
main_src="$src_dir/es.json"
common_src="$src_dir/DCommon-es.json"

# dms materializa la UI embebida al resolver la config. Si el directorio de
# la revisión ya existe con .dankrev correcto, dms lo reutiliza tal cual
# (por eso el parche sobrevive a los reinicios del shell dentro del arranque).
dms_bin="$(command -v dms 2>/dev/null || true)"
if [ -n "$dms_bin" ]; then
    "$dms_bin" doctor >/dev/null 2>&1 || true
fi

apply_file() {
    local src="$1" dst="$2" dir
    [ -f "$src" ] && [ -d "$(dirname "$dst")" ] || return 0
    cmp -s "$src" "$dst" 2>/dev/null && return 0

    dir="$(dirname "$dst")"
    chmod u+w "$dir" 2>/dev/null || true
    rm -f "$dst" 2>/dev/null || true
    if cp "$src" "$dst" 2>/dev/null; then
        chmod 0444 "$dst" 2>/dev/null || true
        chmod 0555 "$dir" 2>/dev/null || true
        echo "dms-es: aplicado $(basename "$src") -> $dst"
    else
        chmod 0555 "$dir" 2>/dev/null || true
    fi
}

shopt -s nullglob
for d in "$runtime_dir"/dms-shell/*/; do
    [ -f "$d/.dankrev" ] || continue
    apply_file "$main_src" "$d/translations/poexports/es.json"
    apply_file "$common_src" "$d/DCommon/translations/poexports/es.json"
done
