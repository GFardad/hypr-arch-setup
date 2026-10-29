#!/usr/bin/env bash
# install.sh - interactive installer for GFardad's Arch + Hyprland setup.
#
# Every category is optional. Nothing is forced. Nothing is deleted without a
# timestamped backup. Existing configs are backed up, never overwritten blindly.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/GFardad/hypr-arch-setup/main/bootstrap.sh)
#   ./install.sh --dry-run              # print the plan, touch nothing
#   ./install.sh --yes recommended      # non-interactive, take the default set
#   ./install.sh --only hypr,kitty      # just those categories
#   ./install.sh --list                 # show categories and exit
#
# Requires: Arch Linux (pacman). paru installed on demand from the AUR if any
# AUR packages are selected and paru is missing. yay is an acceptable fallback.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$REPO_ROOT/scripts/lib/common.sh"

# ---------------- categories ----------------
# id | title | what it does | default-on for strangers?
CATEGORIES=(
  "base|Base system|git, curl, base-devel deps the rest need|yes"
  "hypr|Hyprland config|~/.config/hypr (keybinds, rules, decorations)|yes"
  "kitty|Kitty terminal|~/.config/kitty + themes|yes"
  "shell|Zsh + p10k|.zshrc, .p10k.zsh, plugins, aliases|yes"
  "ags|AGS2 shell|the bar launcher widget (source only; builds types)|no"
  "fonts|Fonts (SF Pro Nerd)|local user fonts + fc-cache|no"
  "cursors|Bibata cursors|~/.icons/Bibata-Modern-Ice|no"
  "wallpaper|Wallpapers + mpvpaper|video walls, ~343M via LFS|no"
  "pkgs|Extra packages|my 635-package list (long, AUR heavy)|no"
  "autosync|24h auto-sync|pull latest from upstream every day|no"
)

state_get() { # $1 = id; prints yes/no
  case "$1" in
    base|hypr|kitty|shell) echo "yes" ;;
    *) echo "no" ;;
  esac
}

# ---------------- args ----------------
DRY_RUN=0; ASSUME=0; ANSWER=""; ONLY=""; LIST_ONLY=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y) ASSUME=1 ;;
    --yes=*) ASSUME=1; ANSWER="${a#--yes=}" ;;
    --only=*) ONLY="${a#--only=}" ;;
    --list) LIST_ONLY=1 ;;
    -h|--help)
      sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) warn "ignoring unknown argument: $a" ;;
  esac
done

ONLY="${ONLY// /}"

if [[ $LIST_ONLY -eq 1 ]]; then
  for c in "${CATEGORIES[@]}"; do
    IFS='|' read -r id title _ _ <<< "$c"
    printf '  %-10s %s\n' "$id" "$title"
  done
  exit 0
fi

# ---------------- menu ----------------
if [[ -z "$ONLY" && $ASSUME -eq 0 ]]; then
  echo
  echo "  Choose what to install (each item is optional):"
  echo
  i=1
  for c in "${CATEGORIES[@]}"; do
    IFS='|' read -r id title _ def <<< "$c"
    [[ "$(state_get "$id")" == "yes" ]] && mark="x" || mark=" "
    printf '   [%s] %d) %-18s %s\n' "$mark" "$i" "$id" "$title"
    i=$((i+1))
  done
  echo
fi

# ---------------- report ----------------
printf '\n'
printf '  Target : %s\n' "$(hostname)"
printf '  User   : %s\n' "$USER"
printf '  Mode   : %s\n' "$([[ $DRY_RUN -eq 1 ]] && echo 'dry-run (nothing changes)' || echo 'install')"
if [[ -z "$ONLY" ]]; then
  printf '  Pick   : %s\n' "$( [[ ${#ANSWER} -eq 0 ]] && echo 'recommended default' || echo "$ANSWER" )"
fi
printf '\n'

# ---------------- selection ----------------
if [[ -n "$ONLY" ]]; then
  for c in "${CATEGORIES[@]}"; do
    IFS='|' read -r id _ _ _ <<< "$c"
    [[ ",$ONLY," == *",$id,"* ]] && SELECTED+=("$id")
  done
fi
