# gtk

Pacote portátil de temas GTK, ícones, cursores e o seletor `theme-pick` (GNOME + Hyprland).

## Estrutura

```
gtk/
├── bin/theme-pick              # seletor interativo (fzf)
├── scripts/
│   ├── vendor-assets.sh        # baixa Manhattan + MacTahoe
│   └── pack-assets.sh          # gera os zips na máquina fonte
├── install.sh                  # instala tudo na máquina destino
└── Assets/
    ├── Manhattan.zip           # tema (vendor)
    ├── MacTahoe.tar.xz         # ícones (vendor)
    ├── themes.zip              # ~/.themes + Manhattan
    ├── icons.zip               # ~/.local/share/icons + MacTahoe
    └── cursors.zip             # Bibata (sem -Right) + Qogir-cursors
```

## Gerar os Assets (máquina fonte)

Na máquina onde os temas já estão instalados:

```bash
git clone <repo> gtk && cd gtk
chmod +x scripts/*.sh

# baixa Manhattan e MacTahoe (amonetlol/dot)
./scripts/vendor-assets.sh

# gera os zips (inclui vendor nos bundles)
./scripts/pack-assets.sh
```

### Vendor assets (incluídos automaticamente)

| Arquivo | Conteúdo | Origem |
|---------|----------|--------|
| `Manhattan.zip` | Tema GTK Manhattan | [amonetlol/dot](https://github.com/amonetlol/dot) |
| `MacTahoe.tar.xz` | Ícones MacTahoe | [amonetlol/dot](https://github.com/amonetlol/dot) |

O `pack-assets.sh` mescla Manhattan em `themes.zip` e MacTahoe em `icons.zip`.

### Cursores incluídos

- Todos os **Bibata** em `/usr/share/icons`, exceto variantes `*-Right`
- **Qogir-cursors**

## Instalar (máquina destino)

Funciona em **qualquer pasta** onde o repo foi baixado:

```bash
chmod +x install.sh

# de dentro do repo
./install.sh

# ou de qualquer lugar
~/Downloads/gtk/install.sh
bash /tmp/gtk/install.sh
```

O instalador detecta automaticamente a pasta do repo e usa paths XDG padrão:

| O quê | Destino padrão | Variável para override |
|-------|----------------|------------------------|
| `theme-pick` | `~/.local/bin/` | `INSTALL_BIN_DIR` |
| temas | `~/.themes/` | `THEMES_DIR` |
| ícones/cursores | `~/.local/share/icons/` | `ICONS_DIR` |
| zips fonte | `<repo>/Assets/` | `ASSETS_DIR` |

Exemplo com paths customizados:

```bash
ASSETS_DIR=~/meus-zips THEMES_DIR=~/.local/share/themes ~/Downloads/gtk/install.sh
```

## Opções do instalador

```bash
./install.sh --bin-only       # só theme-pick
./install.sh --skip-assets    # só theme-pick
./install.sh --themes-only    # só temas
./install.sh --icons-only     # só ícones
./install.sh --cursors-only   # só cursores
```

## Dependências

| Ação | Pacotes |
|------|---------|
| `pack-assets.sh` | `zip`, `unzip`, `tar` |
| `vendor-assets.sh` | `curl` ou `wget`, `unzip` |
| `install.sh` | `unzip` (+ `tar` se MacTahoe presente) |
| `theme-pick` | `bash`, `fzf` (+ opcional: `gsettings`, `nwg-look`, `flatpak`) |
