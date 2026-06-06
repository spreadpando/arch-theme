# theme

Unified GTK + Qt theming, shared across X11/i3 and Wayland/Hyprland.

## Layout

| Path | Surface |
|---|---|
| `.config/gtk-3.0/`, `.config/gtk-4.0/` | GTK widget/icon/cursor/font (`settings.ini` is the source of truth) |
| `.config/qt6ct/qt6ct.conf` | Qt6 theme (style, palette, fonts) |
| `.config/xsettingsd/xsettingsd.conf` | X11-only live settings daemon (inert under Wayland) |
| `.config/systemd/user/theme-dconf.service` | login hook → regenerates dconf from `gtk-3.0/settings.ini` |
| `.local/bin/theme-dconf-sync` | the generator (libadwaita/GTK4/Flatpak read dconf, not `settings.ini`) |
| `etc/sddm.conf.d/zz-theme.conf` | SDDM login-screen theme (installed to `/etc` by `install.sh`, not stowed) |

## Current minimal core

- Widget theme: **Graphite-Dark**  ·  Icons: **breeze-dark** (placeholder)  ·  Cursor: **catppuccin-latte-peach-cursors**
- Qt: qt6ct, **Breeze** style, darker palette
- SDDM: **silent** theme

GTK2 was dropped (no `gtk2` package installed). The old `Nordic-darker`/`Papirus`
icon refs and the `Norder-darker` cursor typo were stripped (none existed on disk).

## Single source of truth

Edit `gtk-3.0/settings.ini`. GTK3 reads it directly; GTK4 reads its own copy;
the dconf surface (for libadwaita/Flatpak) is regenerated from it at login by
`theme-dconf.service`. Run `theme-dconf-sync` by hand to apply immediately.

## Env var (the one WM-divergent piece)

`QT_QPA_PLATFORMTHEME=qt6ct` must be set at **session** level (not shell rc, or
only terminal-launched Qt apps get themed):
- X11/i3 → `~/.xprofile`
- Wayland/Hyprland → `env` in `hypr` config

## Install (fresh machine)

```sh
~/.dotfiles/theme/install.sh
```

Installs deps, fetches the hand-installed assets (Graphite, catppuccin cursors,
silent — best-effort, verify upstream), stows, installs the SDDM drop-in, and
enables the dconf sync service.
