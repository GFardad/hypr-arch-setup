#!/usr/bin/env bash
# capture.sh - MASTER machine only.
# Snapshots the live config out of $HOME into the repo, commits, and pushes.
# Runs every 24h via systemd timer on the machine the setup lives on.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source lib/common.sh

DRY="${1:-}"; [[ "$DRY" == "--dry-run" ]] && DRY=1 || DRY=0

# ---------------- sources: live path -> repo path ----------------
declare -a PAIRS=(
  "$HOME/.config/hypr|config/hypr"
  "$HOME/.config/ags|assets/ags2-shell"
  "$HOME/.config/kitty|config/kitty"
  "$HOME/.config/zellij|config/zellij"
  "$HOME/.config/tmux|config/tmux"
  "$HOME/.zshrc|home/.zshrc"
  "$HOME/.p10k.zsh|home/.p10k.zsh"
  "$HOME/.bashrc|home/.bashrc"
  "$HOME/.local/share/fonts|assets/fonts"
  "$HOME/Downloads/Wallpaper|assets/wallpapers"
  "$HOME/.icons/Bibata-Modern-Ice|assets/icons/Bibata-Modern-Ice"
  "$HOME/.icons/default/index.theme|assets/icons/default/index.theme"
)

# per-source exclude filters (space separated rsync patterns)
declare -A EXCLUDES=(
  ["$HOME/.config/ags"]="@girs/ node_modules/ .git/ style/compiled.css style/compiled_clean.css"
  ["$HOME/.config/hypr"]="wallpaper_effects/.wallpaper_current wallpaper_effects/.wallpaper_modified"
)

say "capture on $(hostname)"
git -C "$REPO_ROOT" pull --rebase --autostash origin "$BRANCH" >/dev/null 2>&1 || true

for pair in "${PAIRS[@]}"; do
  src="${pair%%|*}"; dst="${pair##*|}"
  [[ -e "$src" ]] || { warn "skip (absent): $src"; continue; }
  if [[ -d "$src" ]]; then
    mkdir -p "$REPO_ROOT/$dst"
  else
    mkdir -p "$(dirname "$REPO_ROOT/$dst")"
  fi
  iso=()
  for p in ${EXCLUDES[$src]:-}; do iso+=("--exclude=$p"); done
  if [[ -d "$src" ]]; then
    rsync -a --delete "${iso[@]}" "$src/" "$REPO_ROOT/$dst/" 
  else
    cp -a "$src" "$REPO_ROOT/$dst"
  fi
  ok "synced $src -> $dst"
done

# package manifests (full capture per user intent)
pacman -Qqe               | sort > "$REPO_ROOT/etc/pkgs-explicit.txt"
pacman -Qqm               | sort > "$REPO_ROOT/etc/pkgs-foreign.txt"
pacman -Qen 2>/dev/null   | sort > "$REPO_ROOT/etc/pkgs-explicit-repo.txt"
pacman -Qem 2>/dev/null   | sort > "$REPO_ROOT/etc/pkgs-explicit-aur.txt"
ok "wrote package manifests"

git -C "$REPO_ROOT" add -A
if [[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
  ok "nothing changed in last 24h"
  exit 0
fi
files=$(git -C "$REPO_ROOT" diff --cached --name-only | head -n 10 | paste -sd', ')
n=$(git -C "$REPO_ROOT" diff --cached --name-only | wc -l)
git -C "$REPO_ROOT" commit -q -m "workspace: refresh ${TIMESTAMP}" \
  -m "Auto-synced by hypr-arch-setup (${n} file(s) changed): ${files}"
git_push && ok "pushed to ${REMOTE}"
