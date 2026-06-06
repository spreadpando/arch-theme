# theme

One file for your whole look, applied to both i3 and Hyprland.

## Use it

Edit **`~/.config/theme.conf`**:

```ini
wallpaper   = ~/Pictures/wallpapers/art.jpg
gtk_theme   = Graphite-Dark
qt_style    = Breeze
icon_theme  = breeze-dark
cursor      = catppuccin-latte-peach-cursors
cursor_size = 24
font        = Hack 10
```

`gtk_theme` and `qt_style` are separate because a GTK theme name can't be used
by Qt. Installed `qt_style` options: Breeze, Oxygen, Fusion, Windows. To make Qt
actually match a GTK theme, install `kvantum` + the theme's Kvantum variant and
set `qt_style = kvantum-dark`. The icon theme and font are shared across both.

Then run:

```sh
theme-apply
```

Done. That's the entire system: one config file + one script.

## What theme-apply does

Linux scatters theming across a dozen files; `theme-apply` writes them all from
`theme.conf` so you never touch them by hand:

- `~/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini` (GTK apps)
- `~/.config/qt6ct/qt6ct.conf` (Qt apps)
- dconf via `gsettings` (libadwaita / GTK4 / Flatpak apps)
- `~/.icons/default/index.theme` (X11 cursor)
- the wallpaper (feh on i3, Hyprland's renderer on Wayland)

It runs automatically at i3 startup; Hyprland reads the wallpaper path from
`theme.conf` directly. The Qt env var `QT_QPA_PLATFORMTHEME=qt6ct` lives in
`~/.xprofile` (i3) and the hypr env (Wayland) — set once, rarely touched.

## Package contents

```text
.config/theme.conf        # the one file you edit
.local/bin/theme-apply    # the one script
```

Stow it (`stow theme`) and the two files land in `~`. The files theme-apply
generates (gtk/qt/dconf) are machine-local and not tracked here.

## Themes aren't bundled

`ui_theme`/`icon_theme`/`cursor` must be installed. Current set:

```sh
sudo pacman -S --needed breeze-icons qt6ct
# hand-installed (no package): Graphite-Dark, catppuccin-latte-peach-cursors
```
