# dotfiles (CachyOS + niri + DMS + fish)

Repo manual. Estructura espejo de `~/.config`.

## Restaurar

```fish
# niri (niri/dms/*.kdl NO se copia: lo regenera DMS en ~/.config/niri/dms/)
install -Dm644 dotfiles/niri/config.kdl ~/.config/niri/config.kdl
install -Dm644 dotfiles/niri/cfg/*.kdl ~/.config/niri/cfg/

# DMS / dux-shell >= 2.1 (ruta nueva: ~/.config/dms, no DankMaterialShell)
install -Dm644 dotfiles/DankMaterialShell/*.json ~/.config/dms/

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
