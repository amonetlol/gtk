#!/usr/bin/env bash
# publish-release.sh — publica Assets/*.zip numa GitHub Release (mantenedor)
#
# Uso:
#   ./scripts/publish-release.sh v1.0.0
# Requer: gh auth login

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="${ASSETS_DIR:-$REPO_ROOT/Assets}"
TAG="${1:-}"

die() { echo "publish-release: $*" >&2; exit 1; }

[[ -n "$TAG" ]] || die "uso: publish-release.sh <tag>  (ex: v1.0.0)"
command -v gh >/dev/null 2>&1 || die "gh CLI não encontrado"

[[ -f "$ASSETS/themes.zip" ]] || die "rode ./scripts/pack-assets.sh primeiro"
[[ -f "$ASSETS/icons.zip" ]] || die "icons.zip não encontrado"
[[ -f "$ASSETS/cursors.zip" ]] || die "cursors.zip não encontrado"

# GitHub limita 2 GB por arquivo — divide icons.zip se necessário
MAX_BYTES=$((1900 * 1024 * 1024))
ICONS="$ASSETS/icons.zip"
rm -f "$ASSETS"/icons.zip.part*

if [[ "$(wc -c <"$ICONS")" -gt "$MAX_BYTES" ]]; then
    echo "→ icons.zip grande demais, dividindo em partes..."
    split -b 1900M -d -a 2 "$ICONS" "$ASSETS/icons.zip.part"
    rm -f "$ICONS"
fi

echo "→ Criando release $TAG..."
gh release create "$TAG" \
    --repo "$(gh repo view --json nameWithOwner -q .nameWithOwner)" \
    --title "GTK assets $TAG" \
    --notes "Bundles de temas, ícones e cursores para install.sh" \
    "$ASSETS/themes.zip" \
    "$ASSETS/cursors.zip" \
    "$ASSETS"/icons.zip* \
    2>/dev/null || \
gh release upload "$TAG" \
    "$ASSETS/themes.zip" \
    "$ASSETS/cursors.zip" \
    "$ASSETS"/icons.zip*

echo "Pronto. Atualize config/release.env se não usar /latest/download:"
echo "  GTK_RELEASE_URL=https://github.com/amonetlol/gtk/releases/download/$TAG"
