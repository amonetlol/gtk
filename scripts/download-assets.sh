#!/usr/bin/env bash
# download-assets.sh — baixa bundles para Assets/ (máquina nova, do zero)
#
# Uso:
#   ./scripts/download-assets.sh
#   GTK_RELEASE_URL=https://... ./scripts/download-assets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "${BASH_SOURCE[0]}" != /* ]] && SCRIPT_DIR="$PWD/$(dirname "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="${ASSETS_DIR:-$REPO_ROOT/Assets}"
CONFIG_ENV="$REPO_ROOT/config/release.env"

# shellcheck disable=SC1090
[[ -f "$CONFIG_ENV" ]] && source "$CONFIG_ENV"

RELEASE_URL="${GTK_RELEASE_URL:-https://github.com/amonetlol/gtk/releases/latest/download}"

die() {
    echo "download-assets: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "comando obrigatório não encontrado: $1"
}

download_file() {
    local file="$1"
    local dest="$ASSETS/$file"
    local url="$RELEASE_URL/$file"

    [[ -f "$dest" ]] && { echo "✓ $file (já existe)"; return 0; }

    echo "→ Baixando $file..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL --retry 3 --continue-at - "$url" -o "$dest" || { rm -f "$dest"; return 1; }
    else
        wget -c "$url" -O "$dest" || { rm -f "$dest"; return 1; }
    fi
    echo "  ✓ $dest"
    return 0
}

join_icon_parts() {
    local out="$ASSETS/icons.zip"
    local -a parts=()

    [[ -f "$out" ]] && return 0

    shopt -s nullglob
    parts=("$ASSETS"/icons.zip.part*)
    shopt -u nullglob

    ((${#parts[@]})) || return 1

    echo "→ Montando icons.zip a partir de ${#parts[@]} partes..."
    cat "${parts[@]}" >"$out"
    echo "  ✓ $out"
}

download_icons() {
    local i=0 part

    if [[ -f "$ASSETS/icons.zip" ]]; then
        echo "✓ icons.zip (já existe)"
        return 0
    fi

    if join_icon_parts; then
        return 0
    fi

    if download_file "icons.zip"; then
        return 0
    fi

    echo "→ icons.zip único indisponível, tentando partes..."
    while [[ "$i" -lt 20 ]]; do
        printf -v part 'icons.zip.part%02d' "$i"
        download_file "$part" || break
        ((i++))
    done

    join_icon_parts || die "não foi possível obter icons.zip — publique uma release (scripts/publish-release.sh)"
}

download_vendor_fallback() {
    local base="https://github.com/amonetlol/dot/raw/main/Assets"
    local file dest

    for file in Manhattan.zip MacTahoe.tar.xz; do
        dest="$ASSETS/$file"
        [[ -f "$dest" ]] && continue
        echo "→ Baixando vendor $file (fallback)..."
        if command -v curl >/dev/null 2>&1; then
            curl -fL "$base/$file" -o "$dest"
        else
            wget -qO "$dest" "$base/$file"
        fi
    done
}

main() {
    need_cmd curl 2>/dev/null || need_cmd wget

    mkdir -p "$ASSETS"

    echo "Origem:  $RELEASE_URL"
    echo "Destino: $ASSETS"
    echo

    download_file "themes.zip"
    download_icons
    download_file "cursors.zip"
    download_vendor_fallback

    echo
    echo "Assets prontos:"
    ls -lh "$ASSETS"/themes.zip "$ASSETS"/icons.zip "$ASSETS"/cursors.zip 2>/dev/null || true
}

main "$@"
