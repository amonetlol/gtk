#!/usr/bin/env bash
# vendor-assets.sh — baixa Manhattan e MacTahoe para Assets/
# Fonte: https://github.com/amonetlol/dot/tree/main/Assets

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "${BASH_SOURCE[0]}" != /* ]] && SCRIPT_DIR="$PWD/$(dirname "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="${ASSETS_DIR:-$REPO_ROOT/Assets}"

DOT_ASSETS="https://github.com/amonetlol/dot/raw/main/Assets"

VENDOR_FILES=(
    Manhattan.zip
    MacTahoe.tar.xz
)

die() {
    echo "vendor-assets: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "comando obrigatório não encontrado: $1"
}

download_file() {
    local file="$1"
    local dest="$ASSETS/$file"

    if [[ -f "$dest" ]]; then
        echo "✓ $file (já existe)"
        return 0
    fi

    echo "→ Baixando $file..."
    if command -v curl >/dev/null 2>&1; then
        curl -fL "$DOT_ASSETS/$file" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$dest" "$DOT_ASSETS/$file"
    else
        die "curl ou wget necessário para baixar assets"
    fi
    echo "  ✓ $dest"
}

main() {
    need_cmd unzip
    mkdir -p "$ASSETS"

    echo "Assets: $ASSETS"
    echo

    local file
    for file in "${VENDOR_FILES[@]}"; do
        download_file "$file"
    done

    echo
    echo "Pronto."
    ls -lh "$ASSETS"/Manhattan.zip "$ASSETS"/MacTahoe.tar.xz 2>/dev/null || true
}

main "$@"
