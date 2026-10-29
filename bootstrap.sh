#!/usr/bin/env bash
# bootstrap.sh - the paste-into-a-terminal one-liner.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/GFardad/hypr-arch-setup/main/bootstrap.sh)
#
# Clones the repo to ~/.local/share/hypr-arch-setup, then hands off to the
# interactive installer so the user picks exactly what they want.
#
# Everything below runs as the normal user. Nothing here needs root; the
# installer asks for sudo only for the steps you selected.
set -euo pipefail

REPO_URL="https://github.com/GFardad/hypr-arch-setup.git"
DEST="${HYPR_SETUP_DIR:-$HOME/.local/share/hypr-arch-setup}"

blue()  { printf '\033[1;34m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
red()   { printf '\033[1;31m ✗\033[0m %s\n' "$*" >&2; }

blue "hypr-arch-setup — GFardad's Arch + Hyprland setup"

# --- preflight ---------------------------------------------------
[[ $EUID -ne 0 ]] || { red "Do not run this as root. Run it as your normal user."; exit 1; }

if [[ ! -f /etc/arch-release ]]; then
  red "This looks like $(uname -s) '${ID:-unknown}', not Arch Linux."
  red "The installer assumes pacman/paru; stopping before it breaks your system."
  exit 1
fi

for bin in git curl; do
  command -v "$bin" >/dev/null 2>&1 || { red "missing required tool: $bin"; exit 1; }
done

# git-lfs is needed only to *receive* the asset drop; configs install fine without.
if ! command -v git-lfs >/dev/null 2>&1; then
  printf '\033[1;33m !\033[0m git-lfs not found — wallpapers/fonts will arrive as pointers.\n'
  printf '\033[1;33m !\033[0m Install it with: sudo pacman -S git-lfs   (or: paru -S git-lfs)\n'
  printf '\033[1;33m !\033[0m Continue anyway? The asset drop will be skipped.\n'
  printf '\033[1;33m !\033[0m Re-run with --configs-only to skip them silently.\n'
fi

# --- fetch --------------------------------------------------------
if [[ -d "$DEST/.git" ]]; then
  green "existing checkout at $DEST — updating"
  git -C "$DEST" fetch --quiet origin main
  git -C "$DEST" reset --quiet --hard origin/main
else
  blue "cloning into $DEST …"
  git clone --quiet --depth 1 "$REPO_URL" "$DEST"
fi
green "repo ready: $DEST"

exec bash "$DEST/install.sh" "$@"
