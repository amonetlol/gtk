#!/usr/bin/env bash
# install.sh — instala theme-pick e extrai temas/ícones/cursores
#
# Funciona em qualquer pasta onde o repo foi clonado/baixado.
# Inclui Manhattan (tema) e MacTahoe (ícones).
#
# Uso:
#   ./install.sh
#   ./install.sh --themes-only
#   ./install.sh --skip-assets
#
# Variáveis opcionais (destinos de instalação):
#   INSTALL_BIN_DIR   padrão: $XDG_BIN_HOME ou ~/.local/bin
#   THEMES_DIR        padrão: ~/.themes
#   ICONS_DIR         padrão: $XDG_DATA_HOME/icons ou ~/.local/share/icons
#   ASSETS_DIR        padrão: <repo>/Assets

set -euo pipefail

get_repo_root() {
    local src="${BASH_SOURCE[0]}"
    [[ "$src" != /* ]] && src="$PWD/$src"
    while [[ -L "$src" ]]; do
        local dir
        dir="$(cd "$(dirname "$src")" && pwd)"
        src="$(readlink "$src")"
        [[ "$src" != /* ]] && src="$dir/$src"
    done
    cd "$(dirname "$src")" && pwd
}

REPO_ROOT="$(get_repo_root)"
ASSETS="${ASSETS_DIR:-$REPO_ROOT/Assets}"
BIN_SRC="$REPO_ROOT/bin/theme-pick"

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"

INSTALL_BIN_DIR="${INSTALL_BIN_DIR:-$XDG_BIN_HOME}"
THEMES_DIR="${THEMES_DIR:-$HOME/.themes}"
ICONS_DIR="${ICONS_DIR:-$XDG_DATA_HOME/icons}"

BIN_DST="$INSTALL_BIN_DIR/theme-pick"

MANHATTAN_ZIP="$ASSETS/Manhattan.zip"
MACTAHOE_ARCHIVE="$ASSETS/MacTahoe.tar.xz"

INSTALL_THEMES=1
INSTALL_ICONS=1
INSTALL_CURSORS=1
INSTALL_BIN=1

die() {
    echo "install: $*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "comando obrigatório não encontrado: $1"
}

usage() {
    cat <<EOF
Uso: install.sh [opções]

O script detecta automaticamente a pasta do repo (não importa onde foi baixado).

Instala:
  • theme-pick      → \${INSTALL_BIN_DIR:-~/.local/bin}/theme-pick
  • themes.zip      → \${THEMES_DIR:-~/.themes}  (+ Manhattan.zip se existir)
  • icons.zip       → \${ICONS_DIR:-~/.local/share/icons}  (+ MacTahoe.tar.xz se existir)
  • cursors.zip     → \${ICONS_DIR:-~/.local/share/icons}

Assets lidos de: \${ASSETS_DIR:-<repo>/Assets}

Opções:
  --bin-only       instala só o theme-pick
  --themes-only    instala só temas (zip + Manhattan)
  --icons-only     instala só ícones (zip + MacTahoe)
  --cursors-only   instala só cursors.zip
  --skip-assets    instala só o theme-pick
  -h, --help       mostra esta ajuda
EOF
}

parse_args() {
    local arg
    for arg in "$@"; do
        case "$arg" in
            -h|--help) usage; exit 0 ;;
            --bin-only) INSTALL_THEMES=0; INSTALL_ICONS=0; INSTALL_CURSORS=0 ;;
            --themes-only) INSTALL_BIN=0; INSTALL_ICONS=0; INSTALL_CURSORS=0 ;;
            --icons-only) INSTALL_BIN=0; INSTALL_THEMES=0; INSTALL_CURSORS=0 ;;
            --cursors-only) INSTALL_BIN=0; INSTALL_THEMES=0; INSTALL_ICONS=0 ;;
            --skip-assets) INSTALL_THEMES=0; INSTALL_ICONS=0; INSTALL_CURSORS=0 ;;
            *) die "opção desconhecida: $arg" ;;
        esac
    done
}

install_bin() {
    [[ -f "$BIN_SRC" ]] || die "theme-pick não encontrado em $BIN_SRC"
    mkdir -p "$INSTALL_BIN_DIR"
    install -m755 "$BIN_SRC" "$BIN_DST"
    echo "✓ theme-pick → $BIN_DST"
}

extract_archive() {
    local archive="$1" dest="$2" label="$3"

    [[ -f "$archive" ]] || return 1
    mkdir -p "$dest"
    echo "→ Extraindo $label"
    echo "  de: $archive"

    case "$archive" in
        *.zip)
            unzip -oq "$archive" -d "$dest"
            ;;
        *.tar.xz)
            tar -xJf "$archive" -C "$dest"
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "$archive" -C "$dest"
            ;;
        *.tar)
            tar -xf "$archive" -C "$dest"
            ;;
        *)
            die "formato não suportado: $archive"
            ;;
    esac

    echo "  ✓ $label → $dest"
    return 0
}

install_themes() {
    local installed=0

    if [[ -f "$ASSETS/themes.zip" ]]; then
        extract_archive "$ASSETS/themes.zip" "$THEMES_DIR" "temas GTK (themes.zip)"
        installed=1
    fi

    if extract_archive "$MANHATTAN_ZIP" "$THEMES_DIR" "Tema Manhattan"; then
        installed=1
    fi

    (( installed )) || die "nenhum tema encontrado em $ASSETS (themes.zip ou Manhattan.zip)"
}

install_icons() {
    local installed=0

    if [[ -f "$ASSETS/icons.zip" ]]; then
        extract_archive "$ASSETS/icons.zip" "$ICONS_DIR" "ícones (icons.zip)"
        installed=1
    fi

    if extract_archive "$MACTAHOE_ARCHIVE" "$ICONS_DIR" "Ícones MacTahoe"; then
        installed=1
    fi

    (( installed )) || die "nenhum ícone encontrado em $ASSETS (icons.zip ou MacTahoe.tar.xz)"
}

update_icon_cache() {
    command -v gtk-update-icon-cache >/dev/null 2>&1 || return 0

    local icon_theme
    for icon_theme in "$ICONS_DIR"/*; do
        [[ -d "$icon_theme" && -f "$icon_theme/index.theme" ]] || continue
        gtk-update-icon-cache -f -t "$icon_theme" >/dev/null 2>&1 || true
    done
}

main() {
    parse_args "$@"

    if (( !INSTALL_BIN && !INSTALL_THEMES && !INSTALL_ICONS && !INSTALL_CURSORS )); then
        die "nada para instalar"
    fi

    if (( INSTALL_THEMES || INSTALL_ICONS || INSTALL_CURSORS )); then
        need_cmd unzip
    fi

    if (( INSTALL_ICONS )) && [[ -f "$MACTAHOE_ARCHIVE" ]]; then
        need_cmd tar
    fi

    echo "Repo:    $REPO_ROOT"
    echo "Assets:  $ASSETS"
    echo

    if (( INSTALL_BIN )); then
        install_bin
    fi

    if (( INSTALL_THEMES )); then
        install_themes
    fi

    if (( INSTALL_ICONS )); then
        install_icons
        update_icon_cache
    fi

    if (( INSTALL_CURSORS )); then
        extract_archive "$ASSETS/cursors.zip" "$ICONS_DIR" "cursores" \
            || die "cursors.zip não encontrado em $ASSETS"
        update_icon_cache
    fi

    echo
    echo "Pronto."
    if (( INSTALL_BIN )); then
        echo "Execute: theme-pick"
        [[ ":$PATH:" == *":$INSTALL_BIN_DIR:"* ]] || \
            echo "Dica: export PATH=\"$INSTALL_BIN_DIR:\$PATH\""
    fi
}

main "$@"
