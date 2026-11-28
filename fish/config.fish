source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
end

# prompt (paquete starship; va al final para ganar al prompt por defecto de fish)
starship init fish | source
