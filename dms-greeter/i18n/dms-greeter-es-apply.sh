#!/usr/bin/env bash
# Aplica la traducción es-419 al cache ya extraído de dms-greeter.
# Requiere root: el cache vive en /var/cache/dms-greeter y pertenece a greeter.
#
# El cache se extrae una sola vez por revisión embebida y se reutiliza en los
# siguientes arranques, así que el parche sobrevive reinicios y `dms-greeter
# sync`. Tras una actualización que cambie la revisión hay que reaplicarlo
# (o esperar al siguiente arranque, que lo hace vía ExecStartPre de greetd).
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

shopt -s nullglob
for d in "$cache_root"/*/; do
    [ -f "$d/shell.qml" ] || continue
    apply_file "$main_src" "$d/translations/poexports/es.json"
    apply_file "$common_src" "$d/DCommon/translations/poexports/es.json"
done
