#!/usr/bin/env bash
# install.sh — set up the `theme` dotfiles package on a fresh machine.
#
#   1. install packaged theme deps (pacman)
#   2. fetch the hand-installed assets that no package owns (best-effort)
#   3. stow the config into ~
#   4. install the SDDM drop-in into /etc (needs sudo)
#   5. enable the login-time dconf sync (systemd user service)
#
# Idempotent: re-running skips anything already present.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(dirname "$HERE")"

say()  { printf '\033[1;36m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- 1. packages
PKGS=(stow xsettingsd qt6ct breeze-icons)   # breeze-icons provides the breeze-dark icon theme
say "Installing packages: ${PKGS[*]}"
sudo pacman -S --needed --noconfirm "${PKGS[@]}" || warn "pacman step failed; install ${PKGS[*]} manually"

# ----------------------------------------------------- 2. hand-installed assets
# These are not in any pacman package. URLs are best-effort — verify upstream
# if a fetch fails; the rest of the setup still works with fallbacks.
have_theme() { [ -d "/usr/share/themes/$1" ] || [ -d "$HOME/.themes/$1" ]; }
have_icons() { [ -d "/usr/share/icons/$1" ] || [ -d "$HOME/.icons/$1" ] || [ -d "$HOME/.local/share/icons/$1" ]; }
have_sddm()  { [ -d "/usr/share/sddm/themes/$1" ]; }

if ! have_theme Graphite-Dark; then
  say "Fetching Graphite-Dark GTK theme (vinceliuice)"
  tmp=$(mktemp -d)
  if git clone --depth 1 https://github.com/vinceliuice/Graphite-gtk-theme.git "$tmp"; then
    ( cd "$tmp" && ./install.sh -c dark ) || warn "Graphite install.sh failed"
  else warn "could not clone Graphite-gtk-theme"; fi
  rm -rf "$tmp"
else say "Graphite-Dark already present"; fi

if ! have_icons catppuccin-latte-peach-cursors; then
  warn "Cursor 'catppuccin-latte-peach-cursors' missing — fetch the latte/peach"
  warn "variant from https://github.com/catppuccin/cursors/releases and extract"
  warn "into ~/.local/share/icons/ (left as a manual step; verify the exact name)"
else say "catppuccin-latte-peach-cursors already present"; fi

if ! have_sddm silent; then
  warn "SDDM theme 'silent' missing — install from"
  warn "https://github.com/uiriansan/SilentSDDM (per its README) before relying on it"
else say "SDDM theme 'silent' already present"; fi

# ----------------------------------------------------------------- 3. stow
say "Stowing theme -> $HOME"
( cd "$DOTFILES" && stow theme )

# ---------------------------------------------------------------- 4. SDDM /etc
say "Installing SDDM drop-in to /etc/sddm.conf.d/zz-theme.conf"
sudo install -Dm644 "$HERE/etc/sddm.conf.d/zz-theme.conf" /etc/sddm.conf.d/zz-theme.conf

# ------------------------------------------------------- 5. dconf sync service
say "Enabling theme-dconf.service (login-time dconf sync)"
systemctl --user daemon-reload
systemctl --user enable --now theme-dconf.service

say "Done. Qt apps also need QT_QPA_PLATFORMTHEME=qt6ct in your session env"
say "(set in ~/.xprofile for X11/i3 and hyprland env for Wayland)."
