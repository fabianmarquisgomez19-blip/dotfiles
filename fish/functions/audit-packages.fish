function audit-packages --description "Auditoria seguridad a nivel paquetes (Arch/CachyOS, rootless)"
    argparse 'full' 'timer' 'help' -- $argv
    or return 1

    if set -q _flag_help
        echo "Uso: audit-packages [--full] [--timer]"
        echo "  sin flags : checkupdates + AUR + arch-audit + Qm/Qdt + keyrings + cache (sin sudo)"
        echo "  --full    : anade pacman -Qkk (lento, puede dar falsos positivos en configs)"
        echo "  --timer   : modo no interactivo + notify-send con resumen"
        return 0
    end

    set -l rc 0
    set -l repo_n 0
    set -l aur_n 0
    set -l cve_n 0

    echo "== audit-packages: "(date -u +%Y-%m-%dT%H:%M:%SZ)

    # 1. Oficiales pendientes (rootless, no toca la DB del sistema)
    echo "-- [1/6] repos oficiales (checkupdates)"
    if command -q checkupdates
        set -l updates (checkupdates 2>/dev/null)
        set repo_n (count $updates)
        if test $repo_n -gt 0
            printf '%s\n' $updates
            set rc 1
        else
            echo "OK: sistema al dia"
        end
    else
        echo "AVISO: checkupdates no encontrado (pacman-contrib)"
    end

    # 2. AUR pendientes
    echo "-- [2/6] AUR (paru -Qua)"
    if command -q paru
        set -l aur_updates (paru -Qua 2>/dev/null)
        set aur_n (count $aur_updates)
        if test $aur_n -gt 0
            printf '%s\n' $aur_updates
            set rc 1
        else
            echo "OK: AUR al dia"
        end
    else
        echo "AVISO: paru no instalado"
    end

    # 3. CVEs (solo repos oficiales)
    echo "-- [3/6] vulnerabilidades (arch-audit)"
    if command -q arch-audit
        set -l vulns (arch-audit -u -q 2>/dev/null)
        set cve_n (count $vulns)
        if test $cve_n -gt 0
            printf '%s\n' $vulns
            echo "CRITICO: $cve_n paquete(s) vulnerable(s) con parche disponible -> actualiza ya"
            set rc 2
        else
            echo "OK: sin CVEs con parche pendiente (segun ASA)"
        end
        echo "(nota: arch-audit no cubre AUR; audita PKGBUILDs a mano)"
    else
        echo "AVISO: instala arch-audit: sudo pacman -S --needed arch-audit"
    end

    # 4. Foraneos + huerfanos
    echo "-- [4/6] foraneos (AUR/manual) y huerfanos"
    set -l foreign (pacman -Qm 2>/dev/null)
    set -l foreign_n (count $foreign)
    echo "foraneos: $foreign_n"
    if test $foreign_n -gt 0
        printf '%s\n' $foreign
        echo "-> revisa cada PKGBUILD: paru -G <pkg>; less PKGBUILD; namcap PKGBUILD"
    end
    set -l orphans (pacman -Qdtq 2>/dev/null)
    set -l orphan_n (count $orphans)
    echo "huerfanos: $orphan_n"
    if test $orphan_n -gt 0
        printf '%s\n' $orphans
        echo "-> revisa antes: pactree -r <pkg>; luego: sudo pacman -Rns "(string join ' ' $orphans)
    end

    # 5. Integridad (opt-in por lento/ruidoso)
    echo "-- [5/6] integridad"
    if set -q _flag_full
        echo "pacman -Qkk (puede tardar)..."
        pacman -Qkk 2>&1 | grep -v "0 altered files" | head -n 50
    else
        echo "omitido (usa --full para pacman -Qkk)"
    end
    pacman -Q archlinux-keyring cachyos-keyring 2>/dev/null

    # 6. Cache
    echo "-- [6/6] cache pacman"
    if command -q paccache
        paccache -d -k2 2>/dev/null | tail -n 10
        echo "-> limpia con: sudo paccache -r -k2; paru -c"
    end

    echo "== resumen: repo=$repo_n aur=$aur_n cve=$cve_n foraneos=$foreign_n huerfanos=$orphan_n rc=$rc"

    if set -q _flag_timer
        if command -q notify-send
            if test $rc -eq 2
                notify-send -u critical "audit-packages" "CVEs con parche: $cve_n. Actualiza ya."
            else if test $rc -eq 1
                notify-send "audit-packages" "Updates: repo=$repo_n aur=$aur_n. Sin CVEs."
            else
                notify-send "audit-packages" "OK: sin updates ni CVEs."
            end
        end
    end

    return $rc
end
