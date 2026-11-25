#!/usr/bin/env bash
# Aplica la configuración del repo en ~/.config (ver README.md).
#
# Uso:
#   ./install.sh              copia los archivos, activa servicios y valida
#   ./install.sh --dry-run    muestra qué copiaría y qué activaría, sin tocar nada

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=0
case "${1:-}" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h) echo "Uso: $0 [--dry-run]"; exit 0 ;;
    "") ;;
    *) echo "Uso: $0 [--dry-run]"; exit 2 ;;
esac

shopt -s nullglob

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Modo --dry-run: solo se muestra, no se toca nada"
fi

run() {
    # run <desc>: ejecuta o muestra según el modo
    local desc="$1"; shift
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [DRY] $desc"
    else
        echo "  -> $desc"
        "$@"
    fi
}

# cpf <src> <dst> [mode]: copia src como dst (con -D: crea los padres si faltan)
cpf() {
    run "cp $1 -> $2" install -Dm"${3:-644}" "$1" "$2"
}

echo "== niri =="
cpf "$REPO/niri/config.kdl" "$HOME/.config/niri/config.kdl"
for f in "$REPO"/niri/cfg/*.kdl; do
    cpf "$f" "$HOME/.config/niri/cfg/$(basename "$f")"
done

echo "== entorno (environment.d) =="
for f in "$REPO"/environment.d/*.conf; do
    cpf "$f" "$HOME/.config/environment.d/$(basename "$f")"
done

echo "== DMS / dux-shell >= 2.1 =="
for f in "$REPO"/DankMaterialShell/*.json; do
    cpf "$f" "$HOME/.config/dms/$(basename "$f")"
done
for f in "$REPO"/DankMaterialShell/i18n/*.json; do
    cpf "$f" "$HOME/.config/dms/i18n/$(basename "$f")"
done
cpf "$REPO/DankMaterialShell/i18n/dms-es-apply.sh" "$HOME/.config/dms/i18n/dms-es-apply.sh" 755

echo "== Dux Files =="
cpf "$REPO/dux-files/i18n/duxfiles-es.json" "$HOME/.config/dux-files/i18n/duxfiles-es.json"
cpf "$REPO/dux-files/i18n/dfiles-es-apply.sh" "$HOME/.config/dux-files/i18n/dfiles-es-apply.sh" 755
cpf "$REPO/systemd/user/dfiles.service.d/i18n-es.conf" "$HOME/.config/systemd/user/dfiles.service.d/i18n-es.conf"
run "mkdir -p ~/.config/systemd/user/niri.service.wants" mkdir -p "$HOME/.config/systemd/user/niri.service.wants"
run "ln -sf /usr/lib/systemd/user/dfiles.service ~/.config/systemd/user/niri.service.wants/dfiles.service" ln -sfn /usr/lib/systemd/user/dfiles.service "$HOME/.config/systemd/user/niri.service.wants/dfiles.service"
run "systemctl --user enable --now dfiles.service" systemctl --user enable --now dfiles.service

echo "== fish =="
cpf "$REPO/fish/config.fish" "$HOME/.config/fish/config.fish"
cpf "$REPO/fish/fish_variables" "$HOME/.config/fish/fish_variables"
for f in "$REPO"/fish/functions/*.fish; do
    cpf "$f" "$HOME/.config/fish/functions/$(basename "$f")"
done

echo "== systemd de usuario =="
cpf "$REPO/systemd/user/audit-packages.service" "$HOME/.config/systemd/user/audit-packages.service"
cpf "$REPO/systemd/user/audit-packages.timer" "$HOME/.config/systemd/user/audit-packages.timer"
for f in "$REPO"/systemd/user/xdg-desktop-portal-gtk.service.d/*.conf; do
    cpf "$f" "$HOME/.config/systemd/user/xdg-desktop-portal-gtk.service.d/$(basename "$f")"
done
run "systemctl --user daemon-reload" systemctl --user daemon-reload
run "systemctl --user enable --now audit-packages.timer" systemctl --user enable --now audit-packages.timer

echo "== wireplumber =="
for f in "$REPO"/wireplumber/wireplumber.conf.d/*.conf; do
    cpf "$f" "$HOME/.config/wireplumber/wireplumber.conf.d/$(basename "$f")"
done
run "systemctl --user restart wireplumber" systemctl --user restart wireplumber

echo "== dconf =="
run "dconf load /org/gnome/desktop/wm/preferences/ < dconf/wm-preferences.ini" dconf load /org/gnome/desktop/wm/preferences/ < "$REPO/dconf/wm-preferences.ini"

echo "== firefox =="
found=0
for ff in "$HOME"/.config/mozilla/firefox/*.default-release; do
    [ -d "$ff" ] || continue
    found=1
    cpf "$REPO/firefox/userChrome.css" "$ff/chrome/userChrome.css"
    cpf "$REPO/firefox/user.js" "$ff/user.js"
done
if [ "$found" -eq 0 ]; then
    echo "  (info) no hay ~/.config/mozilla/firefox/*.default-release; copia userChrome.css y user.js a mano"
fi

echo "== greeter (login) en español =="
run "sudo dms-greeter/install-es.sh" sudo "$REPO/dms-greeter/install-es.sh"

echo "== root (udev / modprobe) =="
run "sudo install -m644 udev/rules.d/*.rules -> /etc/udev/rules.d/" sudo install -m644 "$REPO"/udev/rules.d/*.rules /etc/udev/rules.d/
run "sudo install -m644 modprobe/*.conf -> /etc/modprobe.d/" sudo install -m644 "$REPO"/modprobe/*.conf /etc/modprobe.d/
run "sudo udevadm control --reload-rules" sudo udevadm control --reload-rules
run "sudo udevadm trigger --subsystem-match=usb --action=change" sudo udevadm trigger --subsystem-match=usb --action=change

echo "== activar / validar =="
run "systemctl --user restart dms.service" systemctl --user restart dms.service
run "niri validate -c ~/.config/niri/config.kdl" niri validate -c "$HOME/.config/niri/config.kdl"
run "niri msg action load-config-file" niri msg action load-config-file
