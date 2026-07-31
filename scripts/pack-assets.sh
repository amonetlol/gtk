#!/usr/bin/env bash
# pack-assets.sh — empacota temas, ícones e cursores em Assets/*.zip
# Inclui Manhattan (tema) e MacTahoe (ícones) via scripts/vendor-assets.sh
#
# Rode na máquina FONTE (onde os temas já estão instalados) para GERAR os bundles.
# Máquinas novas usam install.sh (baixa os zips da GitHub Release).
#
# Uso:
#   ./scripts/pack-assets.sh
#   ASSETS_DIR=/caminho/out ./scripts/pack-assets.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ "${BASH_SOURCE[0]}" != /* ]] && SCRIPT_DIR="$PWD/$(dirname "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$SCRIPT_DIR" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ASSETS="${ASSETS_DIR:-$REPO_ROOT/Assets}"

THEMES_SRC="${THEMES_SRC:-$HOME/.themes}"
ICONS_SRC="${ICONS_SRC:-$HOME/.local/share/icons}"
CURSORS_SRC="${CURSORS_SRC:-/usr/share/icons}"

MANHATTAN_ZIP="$ASSETS/Manhattan.zip"
MACTAHOE_ARCHIVE="$ASSETS/MacTahoe.tar.xz"

die() {
    echo "pack-assets: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "comando obrigatório não encontrado: $1"
}

ensure_vendor_assets() {
    if [[ -f "$MANHATTAN_ZIP" && -f "$MACTAHOE_ARCHIVE" ]]; then
        return 0
    fi

    echo "→ Baixando assets vendor (Manhattan, MacTahoe)..."
    mkdir -p "$ASSETS"

    if [[ -x "$SCRIPT_DIR/vendor-assets.sh" ]]; then
        ASSETS_DIR="$ASSETS" bash "$SCRIPT_DIR/vendor-assets.sh"
        return 0
    fi

    local base="https://github.com/amonetlol/dot/raw/main/Assets"
    if [[ ! -f "$MANHATTAN_ZIP" ]]; then
        if command -v curl >/dev/null 2>&1; then
            curl -fL "$base/Manhattan.zip" -o "$MANHATTAN_ZIP"
        else
            wget -qO "$MANHATTAN_ZIP" "$base/Manhattan.zip"
        fi
    fi
    if [[ ! -f "$MACTAHOE_ARCHIVE" ]]; then
        if command -v curl >/dev/null 2>&1; then
            curl -fL "$base/MacTahoe.tar.xz" -o "$MACTAHOE_ARCHIVE"
        else
            wget -qO "$MACTAHOE_ARCHIVE" "$base/MacTahoe.tar.xz"
        fi
    fi
}

collect_cursors() {
    local -a cursors=()
    local name

    for name in "$CURSORS_SRC"/Bibata-*; do
        [[ -d "$name" ]] || continue
        name="$(basename "$name")"
        [[ "$name" == *-Right ]] && continue
        cursors+=("$name")
    done

    [[ -d "$CURSORS_SRC/Qogir-cursors" ]] && cursors+=("Qogir-cursors")

    ((${#cursors[@]})) || die "nenhum cursor encontrado em $CURSORS_SRC"
    printf '%s\n' "${cursors[@]}"
}

pack_themes() {
    local out="$ASSETS/themes.zip"
    local staging
    staging="$(mktemp -d)"

    echo "→ Empacotando temas"

    if [[ -d "$THEMES_SRC" ]]; then
        echo "  de $THEMES_SRC"
        cp -a "$THEMES_SRC"/. "$staging/"
    fi

    if [[ -f "$MANHATTAN_ZIP" ]]; then
        echo "  + Manhattan"
        unzip -oq "$MANHATTAN_ZIP" -d "$staging"
    else
        echo "  ! Manhattan.zip não encontrado (rode scripts/vendor-assets.sh)"
    fi

    rm -f "$out"
    (cd "$staging" && zip -qr "$out" .)
    rm -rf "$staging"
    echo "  criado: $out ($(du -h "$out" | cut -f1))"
}

read_include_list() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    grep -v '^[[:space:]]*#' "$file" | grep -v '^[[:space:]]*$' || true
}

pack_icons() {
    local out="$ASSETS/icons.zip"
    local staging include_file="$REPO_ROOT/config/icons.include"
    local name
    staging="$(mktemp -d)"

    echo "→ Empacotando ícones"

    if [[ -f "$include_file" ]]; then
        echo "  lista: config/icons.include"
        while IFS= read -r name; do
            [[ -z "$name" || "$name" == \#* ]] && continue
            [[ -d "$ICONS_SRC/$name" ]] || { echo "  ! não encontrado: $name"; continue; }
            cp -a "$ICONS_SRC/$name" "$staging/"
            echo "  + $name"
        done < "$include_file"
    elif [[ -d "$ICONS_SRC" ]]; then
        echo "  de $ICONS_SRC (todos)"
        cp -a "$ICONS_SRC"/. "$staging/"
        rm -rf "$staging/default"
    else
        die "nenhuma fonte de ícones (defina ICONS_SRC ou config/icons.include)"
    fi

    if [[ -f "$MACTAHOE_ARCHIVE" ]]; then
        echo "  + MacTahoe"
        tar -xJf "$MACTAHOE_ARCHIVE" -C "$staging"
    else
        echo "  ! MacTahoe.tar.xz não encontrado (rode scripts/vendor-assets.sh)"
    fi

    rm -f "$out"
    (cd "$staging" && zip -qr "$out" .)
    rm -rf "$staging"
    echo "  criado: $out ($(du -h "$out" | cut -f1))"
}

pack_cursors() {
    local out="$ASSETS/cursors.zip"
    local -a cursors=()
    mapfile -t cursors < <(collect_cursors)

    echo "→ Empacotando cursores (${#cursors[@]} pacotes):"
    printf '  - %s\n' "${cursors[@]}"

    rm -f "$out"
    (cd "$CURSORS_SRC" && zip -qr "$out" "${cursors[@]}")
    echo "  criado: $out ($(du -h "$out" | cut -f1))"
}

main() {
    need_cmd zip
    need_cmd du
    need_cmd unzip
    need_cmd tar

    mkdir -p "$ASSETS"
    ensure_vendor_assets

    echo "Destino: $ASSETS"
    echo

    pack_themes
    pack_icons
    pack_cursors

    echo
    echo "Pronto. Assets gerados em $ASSETS"
    ls -lh "$ASSETS"/*.zip "$ASSETS"/Manhattan.zip "$ASSETS"/MacTahoe.tar.xz 2>/dev/null || true
}

main "$@"
