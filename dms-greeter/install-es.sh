#!/usr/bin/env bash
# Instala el override de traducción es-419 del login (DMS Greeter).
# Requiere root: el cache del greeter y greetd viven fuera de $HOME.
#
# Uso: sudo ~/dotfiles-main/dms-greeter/install-es.sh
#
# Deja en /etc/greetd/i18n/ los catálogos y el script que aplica el parche,
# instala el drop-in de greetd.service (ExecStartPre + ExecStartPost --wait) y
# parchea la revisión del cache ya extraída (si existe), sin esperar al
# siguiente arranque.
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src_dir="$repo_dir/dms-greeter/i18n"

if [ "$(id -u)" -ne 0 ]; then
    echo "install-greeter-es: se necesita root (sudo)" >&2
    exit 1
fi

for f in es.json DCommon-es.json dms-greeter-es-apply.sh; do
    [ -f "$src_dir/$f" ] || { echo "install-greeter-es: falta $src_dir/$f" >&2; exit 1; }
done

install -d -m 0755 /etc/greetd/i18n
install -m 0644 "$src_dir/es.json" /etc/greetd/i18n/es.json
install -m 0644 "$src_dir/DCommon-es.json" /etc/greetd/i18n/DCommon-es.json
install -m 0755 "$src_dir/dms-greeter-es-apply.sh" /etc/greetd/i18n/dms-greeter-es-apply.sh

install -D -m 0644 "$repo_dir/systemd/system/greetd.service.d/i18n-es.conf" \
    /etc/systemd/system/greetd.service.d/i18n-es.conf

systemctl daemon-reload

# Parchea la revisión actual del cache; las siguientes se parchean solas con
# el ExecStartPre del drop-in.
/etc/greetd/i18n/dms-greeter-es-apply.sh
