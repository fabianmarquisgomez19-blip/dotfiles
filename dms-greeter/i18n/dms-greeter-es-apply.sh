#!/usr/bin/env bash
# Aplica la traducción es-419 al cache ya extraído de dms-greeter.
# Requiere root: el cache vive en /var/cache/dms-greeter y pertenece a greeter.
#
# El cache se extrae una sola vez por revisión embebida y se reutiliza en los
# siguientes arranques, así que el parche sobrevive reinicios y `dms-greeter
# sync`. Hay dos modos:
#
#   (sin args)  parchea las revisiones que ya existen. Es el modo de
#               ExecStartPre de greetd.service: cubre el caso en que el cache
#               está pero le falta es.json (p. ej. tras instalarlo).
#   --wait      espera a que el greeter extraiga una revisión nueva y la
#               parchea antes de que QML cargue las traducciones. Es el modo de
#               ExecStartPost: tras una actualización de dux-greeter-bin la
#               revisión cambia y en el arranque todavía no existe. La señal
#               fiable de "extracción terminada" es el proceso `qs -p <rev>`,
#               que dms-greeter lanza justo después de extraer.
#
# Sin --wait, una revisión nueva se parchearía en el arranque siguiente (cuando
# la carpeta ya existe). Con --wait, en el mismo arranque.
set -u

src_dir="${DMS_GREETER_ES_DIR:-/etc/greetd/i18n}"
cache_root="${DMS_GREETER_CACHE:-/var/cache/dms-greeter/.cache/dms-greeter-shell}"
main_src="$src_dir/es.json"
common_src="$src_dir/DCommon-es.json"

if [ "$(id -u)" -ne 0 ]; then
    echo "dms-greeter-es: se necesita root" >&2
    exit 1
fi

[ -f "$main_src" ] || { echo "dms-greeter-es: falta $main_src" >&2; exit 1; }
[ -f "$common_src" ] || { echo "dms-greeter-es: falta $common_src" >&2; exit 1; }
[ -d "$cache_root" ] || exit 0

apply_file() {
    local src="$1" dst="$2" dir
    [ -f "$src" ] && [ -d "$(dirname "$dst")" ] || return 0
    cmp -s "$src" "$dst" 2>/dev/null && return 0

    dir="$(dirname "$dst")"
    chmod u+w "$dir" 2>/dev/null || true
    rm -f "$dst" 2>/dev/null || true
    if cp "$src" "$dst" 2>/dev/null; then
        chown greeter:greeter "$dst" 2>/dev/null || true
        chmod 0444 "$dst" 2>/dev/null || true
        echo "dms-greeter-es: aplicado $(basename "$src") -> $dst"
    fi
    chmod 0555 "$dir" 2>/dev/null || true
}

apply_tree() {
    local d="${1%/}"
    [ -f "$d/shell.qml" ] || return 0
    apply_file "$main_src" "$d/translations/poexports/es.json"
    apply_file "$common_src" "$d/DCommon/translations/poexports/es.json"
}

scan_trees() {
    local d
    shopt -s nullglob
    for d in "$cache_root"/*/; do
        apply_tree "$d"
    done
}

if [ "${1:-}" = "--wait" ]; then
    deadline=$((SECONDS + 20))
    target=""
    while [ "$SECONDS" -lt "$deadline" ]; do
        shopt -s nullglob
        for d in "$cache_root"/*/; do
            d="${d%/}"
            [ -f "$d/shell.qml" ] || continue
            if pgrep -f -- "qs -p $d" >/dev/null 2>&1; then
                target="$d"
                break 2
            fi
        done
        sleep 0.02
    done

    if [ -z "$target" ]; then
        echo "dms-greeter-es: no se detectó la extracción del greeter en $cache_root" >&2
        exit 0
    fi

    apply_tree "$target"
    scan_trees
else
    scan_trees
fi
