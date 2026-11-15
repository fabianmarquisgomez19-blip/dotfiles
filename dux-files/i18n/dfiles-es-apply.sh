#!/usr/bin/env bash
# Aplica la traducción completa al español (es-419) sobre la UI embebida de
# dux-files. dfiles extrae su UI en $XDG_RUNTIME_DIR/dfiles-shell/<rev>/ en
# CADA arranque (reescribe el árbol, así que un parche previo se pierde).
# Por eso el modo --wait, pensado como ExecStartPost= de dfiles.service:
# espera a que termine la extracción (el proceso `qs -p <rev>` ya está vivo)
# y escribe es.json antes de que QML cargue las traducciones (~1 s de margen).
#
# El override vive en ~/.config/dux-files/i18n/ (copia de dux-files/i18n/).
# DCommon (widgets compartidos) reutiliza la traducción de DMS: comparte los
# mismos 130 contextos y claves.
set -u

config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
src_dir="$config_home/dux-files/i18n"
runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
main_src="$src_dir/duxfiles-es.json"
common_src="$config_home/dms/i18n/DCommon-es.json"
[ -f "$common_src" ] || common_src="$src_dir/DCommon-es.json"

changes=0
found=0

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
        changes=$((changes + 1))
        echo "dfiles-es: aplicado $(basename "$src") -> $dst"
    else
        chmod 0555 "$dir" 2>/dev/null || true
    fi
}

apply_tree() {
    local d="$1"
    [ -f "$d/translations/en.json" ] || return 0
    found=1
    apply_file "$main_src" "$d/translations/poexports/es.json"
    [ -d "$d/DCommon/translations/poexports" ] \
        && apply_file "$common_src" "$d/DCommon/translations/poexports/es.json"
}

scan_trees() {
    local d
    shopt -s nullglob
    for d in "$runtime_dir"/dfiles-shell/*/; do
        apply_tree "$d"
    done
}

if [ "${1:-}" = "--wait" ]; then
    # ExecStartPost: esperar a que dfiles termine de extraer la UI. La señal
    # fiable es el proceso `qs -p <rev>`, que se lanza justo después.
    deadline=$((SECONDS + 20))
    target=""
    while [ "$SECONDS" -lt "$deadline" ]; do
        for d in "$runtime_dir"/dfiles-shell/*/; do
            [ -f "$d/translations/en.json" ] || continue
            if pgrep -f "qs -p ${d%/}" >/dev/null 2>&1; then
                target="${d%/}"
                break 2
            fi
        done
        sleep 0.02
    done

    if [ -z "$target" ]; then
        echo "dfiles-es: no se detectó la extracción de la UI (¿DFILES_SHELL_DIR activo?)" >&2
        exit 0
    fi
    apply_tree "$target/"
else
    scan_trees
    if [ "$found" -eq 0 ]; then
        echo "dfiles-es: no hay revisión extraída en $runtime_dir/dfiles-shell" >&2
    fi
fi

if [ "$changes" -eq 0 ]; then
    exit 0
fi
