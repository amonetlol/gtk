#!/usr/bin/env bash
# repack-vendor.sh — mescla Manhattan e MacTahoe nos zips existentes
# Útil quando themes.zip/icons.zip já existem e só faltam os vendor assets.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "${BASH_SOURCE[0]}" != /* ]] && SCRIPT_DIR="$PWD/$(dirname "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="${ASSETS_DIR:-$REPO_ROOT/Assets}"

MANHATTAN_ZIP="$ASSETS/Manhattan.zip"
MACTAHOE_ARCHIVE="$ASSETS/MacTahoe.tar.xz"
THEMES_ZIP="$ASSETS/themes.zip"
ICONS_ZIP="$ASSETS/icons.zip"

die() { echo "repack-vendor: $*" >&2; exit 1; }

ensure_vendor() {
    [[ -f "$MANHATTAN_ZIP" && -f "$MACTAHOE_ARCHIVE" ]] \
        || ASSETS_DIR="$ASSETS" bash "$SCRIPT_DIR/vendor-assets.sh"
}

repack_themes() {
    local staging tmp_zip
    staging="$(mktemp -d)"
    tmp_zip="$(mktemp)"

    [[ -f "$THEMES_ZIP" ]] || die "themes.zip não encontrado em $ASSETS"

    echo "→ Mesclando Manhattan em themes.zip"
    unzip -q "$THEMES_ZIP" -d "$staging"
    unzip -oq "$MANHATTAN_ZIP" -d "$staging"
    (cd "$staging" && zip -qr "$tmp_zip" .)
    mv "$tmp_zip" "$THEMES_ZIP"
    rm -rf "$staging"
    echo "  ✓ $THEMES_ZIP"
}

repack_icons() {
    local staging tmp_zip
    staging="$(mktemp -d)"
    tmp_zip="$(mktemp)"

    [[ -f "$ICONS_ZIP" ]] || die "icons.zip não encontrado em $ASSETS"

    echo "→ Mesclando MacTahoe em icons.zip"
    unzip -q "$ICONS_ZIP" -d "$staging"
    tar -xJf "$MACTAHOE_ARCHIVE" -C "$staging"
    (cd "$staging" && zip -qr "$tmp_zip" .)
    mv "$tmp_zip" "$ICONS_ZIP"
    rm -rf "$staging"
    echo "  ✓ $ICONS_ZIP"
}

main() {
    command -v zip >/dev/null || die "zip não encontrado"
    command -v unzip >/dev/null || die "unzip não encontrado"
    command -v tar >/dev/null || die "tar não encontrado"

    ensure_vendor
    repack_themes
    repack_icons
    echo "Pronto."
}

main "$@"
