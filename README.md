# dotfiles (CachyOS + niri + DMS + fish)

Repo manual. Estructura espejo de `~/.config`.

## Restaurar

```fish
cp dotfiles/niri/config.kdl ~/.config/niri/config.kdl
cp dotfiles/niri/cfg/* ~/.config/niri/cfg/
# solo si sabes lo que haces (DMS los genera):
cp dotfiles/niri/dms/* ~/.config/niri/dms/
cp dotfiles/fish/config.fish dotfiles/fish/fish_variables ~/.config/fish/
cp dotfiles/DankMaterialShell/*.json ~/.config/DankMaterialShell/
cp -r dotfiles/wireplumber/wireplumber.conf.d ~/.config/wireplumber/
sudo cp dotfiles/udev/rules.d/*.rules /etc/udev/rules.d/
sudo cp dotfiles/modprobe/*.conf /etc/modprobe.d/
sudo udevadm control --reload-rules
niri validate
```

Ver `AGENTS.md` para reglas.
