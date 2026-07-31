# gtk

Pacote para instalar temas GTK, ícones, cursores e o seletor `theme-pick` em **máquinas novas** (GNOME + Hyprland).

## Instalar do zero (máquina nova)

```bash
git clone https://github.com/amonetlol/gtk.git
cd gtk
chmod +x install.sh
./install.sh
```

O `install.sh` automaticamente:

1. **Baixa** `themes.zip`, `icons.zip` e `cursors.zip` da [GitHub Release](https://github.com/amonetlol/gtk/releases)
2. Instala `theme-pick` em `~/.local/bin/`
3. Extrai tudo em `~/.themes` e `~/.local/share/icons`

Depois:

```bash
theme-pick
```

### Dependências na máquina nova

```bash
# Arch
sudo pacman -S unzip curl fzf

# Debian/Ubuntu
sudo apt install unzip curl fzf
```

## Estrutura

```
gtk/
├── bin/theme-pick
├── config/
│   ├── release.env          # URL da GitHub Release
│   └── icons.include        # lista de ícones no bundle (mantenedor)
├── install.sh               # instala do zero (baixa + extrai)
├── scripts/
│   ├── download-assets.sh   # só download dos zips
│   ├── pack-assets.sh       # gera zips (mantenedor)
│   ├── publish-release.sh   # publica na GitHub Release
│   └── vendor-assets.sh
└── Assets/                  # zips baixados/gerados (não vão pro git)
```

## De onde vêm os arquivos

| Arquivo | Na máquina nova | Origem |
|---------|-----------------|--------|
| `themes.zip` | **Download** da Release | Gerado pelo mantenedor |
| `icons.zip` | **Download** da Release | Gerado pelo mantenedor |
| `cursors.zip` | **Download** da Release | Gerado pelo mantenedor |
| `Manhattan.zip` | No git ou fallback download | [amonetlol/dot](https://github.com/amonetlol/dot) |
| `MacTahoe.tar.xz` | No git ou fallback download | [amonetlol/dot](https://github.com/amonetlol/dot) |

Os zips grandes **não ficam no git** (limite de 100 MB do GitHub). Ficam na **GitHub Release**.

## Fluxo do mantenedor (gerar e publicar)

Na máquina onde os temas já estão instalados:

```bash
# 1. Gera os bundles a partir de ~/.themes, ~/.local/share/icons, /usr/share/icons
./scripts/pack-assets.sh

# 2. Publica na GitHub Release (divide icons.zip se > 1.9 GB)
./scripts/publish-release.sh v1.0.0
```

Edite `config/icons.include` para controlar quais pacotes de ícones entram no bundle.

## Opções do instalador

```bash
./install.sh                  # download + instala tudo
./install.sh --skip-download    # usa Assets/ já presentes
./install.sh --bin-only         # só theme-pick
./install.sh --themes-only
./install.sh --icons-only
./install.sh --cursors-only
```

## Variáveis de ambiente

| Variável | Uso |
|----------|-----|
| `GTK_RELEASE_URL` | URL base dos zips (padrão: `config/release.env`) |
| `ASSETS_DIR` | Onde salvar/ler os zips |
| `THEMES_DIR` | Destino dos temas (`~/.themes`) |
| `ICONS_DIR` | Destino dos ícones (`~/.local/share/icons`) |
| `INSTALL_BIN_DIR` | Destino do theme-pick (`~/.local/bin`) |

## Cursores incluídos no bundle

- Todos os **Bibata** (exceto `*-Right`)
- **Qogir-cursors**
