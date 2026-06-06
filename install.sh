#!/usr/bin/env bash
# install.sh — set up the `theme` dotfiles package. Idempotent & re-runnable.
#
# Manage dependencies by editing the two arrays below:
#   PACMAN_PKGS : official-repo packages (installed with --needed)
#   REPOS       : hand-installed themes/cursors that no package owns
#
# Usage:
#   ./install.sh              install/sync everything (skips what's present)
#   ./install.sh --force      also reinstall assets that already exist
#   ./install.sh --no-assets  skip the REPOS step (config/stow/sddm/service only)
#   ./install.sh --no-sddm    skip writing the /etc SDDM drop-in
set -euo pipefail

# ───────────────────────────────────────────── dependencies (edit these)
PACMAN_PKGS=(
  stow
  xsettingsd
  qt6ct
  breeze-icons          # provides the breeze-dark icon theme
)

# Format: "name|kind|git-url|build"
#   kind  : theme | icon | sddm   — decides where presence is checked / removed
#   build : command run *inside the fresh clone*, or the literal MANUAL to just
#           print a reminder (for assets whose build isn't verified yet)
REPOS=(
  "Graphite-Dark|theme|https://github.com/vinceliuice/Graphite-gtk-theme.git|./install.sh -c dark"
  "catppuccin-latte-peach-cursors|icon|https://github.com/catppuccin/cursors.git|MANUAL"
  "silent|sddm|https://github.com/uiriansan/SilentSDDM.git|MANUAL"
)

# ───────────────────────────────────────────── internals
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(dirname "$HERE")"
FORCE=0 DO_ASSETS=1 DO_SDDM=1
for a in "$@"; do case "$a" in
  --force)     FORCE=1 ;;
  --no-assets) DO_ASSETS=0 ;;
  --no-sddm)   DO_SDDM=0 ;;
  -h|--help)   sed -n '2,12p' "$0"; exit 0 ;;
  *) echo "unknown arg: $a (try --help)" >&2; exit 2 ;;
esac; done

c()    { printf '\033[1;%sm%s\033[0m' "$1" "$2"; }
say()  { printf '%s %s\n' "$(c 36 '::')" "$*"; }
ok()   { printf '%s %s\n' "$(c 32 ' ✓')" "$*"; }
warn() { printf '%s %s\n' "$(c 33 ' !')" "$*" >&2; }
die()  { printf '%s %s\n' "$(c 31 '✗✗')" "$*" >&2; exit 1; }
need() { command -v "$1" >/dev/null || die "required tool '$1' not found"; }

# where each kind installs to (used for presence checks and --force removal)
asset_roots() { # kind -> prints candidate dirs
  case "$1" in
    theme) printf '%s\n' "/usr/share/themes" "$HOME/.themes" "$HOME/.local/share/themes" ;;
    icon)  printf '%s\n' "/usr/share/icons"  "$HOME/.icons"  "$HOME/.local/share/icons"  ;;
    sddm)  printf '%s\n' "/usr/share/sddm/themes" ;;
    *) die "unknown asset kind: $1" ;;
  esac
}
asset_present() { local r; while read -r r; do [ -d "$r/$1" ] && return 0; done < <(asset_roots "$2"); return 1; }

# ───────────────────────────────────────────── steps
install_packages() {
  need pacman
  say "Packages: ${PACMAN_PKGS[*]}"
  sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
  ok "packages present"
}

install_assets() {
  need git
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN   # auto-clean clones
  local entry name kind url build r
  for entry in "${REPOS[@]}"; do
    IFS='|' read -r name kind url build <<<"$entry"
    [ -n "$name" ] || continue

    if asset_present "$name" "$kind"; then
      if [ "$FORCE" -eq 0 ]; then ok "$name already installed"; continue; fi
      say "Removing existing $name (--force)"
      while read -r r; do
        [ -d "$r/$name" ] || continue
        case "$r" in /usr/*) sudo rm -rf "${r:?}/${name:?}" ;; *) rm -rf "${r:?}/${name:?}" ;; esac
      done < <(asset_roots "$kind")
    fi

    if [ "$build" = MANUAL ]; then
      warn "$name: not auto-built yet — install manually from $url"
      continue
    fi

    say "Installing $name from $url"
    git clone --depth 1 "$url" "$tmp/$name" || { warn "clone failed: $url"; continue; }
    ( cd "$tmp/$name" && eval "$build" )    || { warn "build failed: $name"; continue; }
    asset_present "$name" "$kind" && ok "$name installed" \
      || warn "$name: build ran but not found in expected location"
  done
}

do_stow() {
  need stow
  say "Stowing theme -> \$HOME (restow: adds new, prunes stale links)"
  ( cd "$DOTFILES" && stow -R theme )
  ok "stowed"
}

install_sddm() {
  local src="$HERE/etc/sddm.conf.d/zz-theme.conf" dst=/etc/sddm.conf.d/zz-theme.conf
  if [ -f "$dst" ] && cmp -s "$src" "$dst"; then ok "SDDM drop-in up to date"; return; fi
  say "Installing SDDM drop-in -> $dst"
  sudo install -Dm644 "$src" "$dst"
  ok "SDDM drop-in installed (theme=silent)"
}

enable_service() {
  say "Enabling theme-dconf.service (login-time dconf sync)"
  systemctl --user daemon-reload
  systemctl --user enable --now theme-dconf.service
  ok "dconf sync enabled"
}

# ───────────────────────────────────────────── run
install_packages
if [ "$DO_ASSETS" -eq 1 ]; then install_assets; else warn "skipping assets (--no-assets)"; fi
do_stow
if [ "$DO_SDDM" -eq 1 ]; then install_sddm; else warn "skipping SDDM drop-in (--no-sddm)"; fi
enable_service
say "$(c 32 'All done.') Qt env (QT_QPA_PLATFORMTHEME=qt6ct) takes effect on next login."
