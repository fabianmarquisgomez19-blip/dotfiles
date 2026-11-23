# dotfiles (CachyOS + niri + DMS + fish)

Repo manual. Estructura espejo de `~/.config`.

Aplica todo el flujo de "Restaurar" con `./install.sh`; con `--dry-run`
muestra qué copiaría y qué activaría, sin tocar nada.

## Restaurar

```fish
# niri (niri/dms/*.kdl NO se copia: lo regenera DMS en ~/.config/niri/dms/)
install -Dm644 dotfiles/niri/config.kdl ~/.config/niri/config.kdl
install -Dm644 dotfiles/niri/cfg/*.kdl ~/.config/niri/cfg/

# DMS / dux-shell >= 2.1 (ruta nueva: ~/.config/dms, no DankMaterialShell)
install -Dm644 dotfiles/DankMaterialShell/*.json ~/.config/dms/
install -Dm644 dotfiles/DankMaterialShell/i18n/*.json ~/.config/dms/i18n/
install -Dm755 dotfiles/DankMaterialShell/i18n/dms-es-apply.sh ~/.config/dms/i18n/

# Dux Files: traducción es-419 (658 términos) + drop-in que la reaplica en cada arranque
install -Dm644 dotfiles/dux-files/i18n/duxfiles-es.json ~/.config/dux-files/i18n/duxfiles-es.json
install -Dm755 dotfiles/dux-files/i18n/dfiles-es-apply.sh ~/.config/dux-files/i18n/dfiles-es-apply.sh
install -Dm644 dotfiles/systemd/user/dfiles.service.d/i18n-es.conf ~/.config/systemd/user/dfiles.service.d/
mkdir -p ~/.config/systemd/user/niri.service.wants
ln -sf /usr/lib/systemd/user/dfiles.service ~/.config/systemd/user/niri.service.wants/dfiles.service
systemctl --user daemon-reload
systemctl --user enable --now dfiles.service

# fish
install -Dm644 dotfiles/fish/config.fish ~/.config/fish/config.fish
install -Dm644 dotfiles/fish/fish_variables ~/.config/fish/fish_variables
install -Dm644 dotfiles/fish/functions/*.fish ~/.config/fish/functions/

# systemd de usuario
install -Dm644 dotfiles/systemd/user/audit-packages.service ~/.config/systemd/user/
install -Dm644 dotfiles/systemd/user/audit-packages.timer ~/.config/systemd/user/
install -Dm644 dotfiles/systemd/user/xdg-desktop-portal-gtk.service.d/*.conf ~/.config/systemd/user/xdg-desktop-portal-gtk.service.d/
systemctl --user daemon-reload
systemctl --user enable --now audit-packages.timer

# wireplumber
install -Dm644 dotfiles/wireplumber/wireplumber.conf.d/*.conf ~/.config/wireplumber/wireplumber.conf.d/
systemctl --user restart wireplumber

# root (udev / modprobe)
sudo install -m644 dotfiles/udev/rules.d/*.rules /etc/udev/rules.d/
sudo install -m644 dotfiles/modprobe/*.conf /etc/modprobe.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=usb --action=change

# greeter (login) en español: catálogos + drop-in ExecStartPre/Post + parche del cache
sudo dotfiles/dms-greeter/install-es.sh

# dconf: quitar botones de ventana (min/max/cerrar) en apps GTK3/GTK4
dconf load /org/gnome/desktop/wm/preferences/ < dotfiles/dconf/wm-preferences.ini

# Firefox: sin botones de ventana (userChrome; Firefox 159+ usa ~/.config/mozilla)
# Sustituye PROFILE por tu perfil: ls ~/.config/mozilla/firefox
set -l ff ~/.config/mozilla/firefox/PROFILE.default-release
install -Dm644 dotfiles/firefox/userChrome.css $ff/chrome/userChrome.css
install -Dm644 dotfiles/firefox/user.js $ff/user.js

# DMS arranca por dms.service, no por spawn-at-startup
systemctl --user restart dms.service
niri validate -c ~/.config/niri/config.kdl
niri msg action load-config-file
```

Ver `AGENTS.md` para reglas.
