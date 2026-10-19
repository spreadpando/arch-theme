# theme

One file for your whole look, applied to both i3 and Hyprland.

## Use it

Edit **`~/.config/theme.conf`**. It's yours and not in git: `theme-apply` creates it
from `theme.default.conf` on first run. For example:

```ini
wallpaper   = ~/Pictures/wallpapers/art.jpg
wallpaper_speed = 1
gtk_theme   = Graphite-Dark
qt_style    = Breeze
icon_theme  = breeze-dark
cursor      = catppuccin-latte-peach-cursors
cursor_size = 24
font        = Hack 10
display_font = Lilex Nerd Font
bar_font    = Lilex Nerd Font
```

`display_font` is for big decorative text (the hyprlock clock). `bar_font` is
for small accent text: waybar, notification titles (dunst) and the rofi
launcher's mode buttons. Only the family is set here; sizes stay in each app's
config. The fonts themselves must be installed (`~/.local/share/fonts` or
`/usr/local/share/fonts`).

`wallpaper` can also be a video (`.mp4`/`.mkv`/`.webm`/`.mov`) — on Hyprland it's
cropped per monitor with ffmpeg and played by mpvpaper. `wallpaper_speed` is the
playback rate for that case (`0.1` = slow-mo); it's ignored for images and on i3.

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
- accent fonts: `hypr/hyprlock-fonts.conf` (`$accent` clock, `$bar` date and
  password field), plus
  `waybar/theme-fonts.css`, `rofi/theme-fonts.rasi` and
  `dunst/dunstrc.d/50-theme-fonts.conf`, which those apps' configs import

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
