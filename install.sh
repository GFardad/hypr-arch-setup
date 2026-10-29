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
# shellcheck source=scripts/lib/apply.sh
source "$REPO_ROOT/scripts/lib/apply.sh"

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

cat_id() { # 1 for "id title desc def" or id, else empty
  local want="$1" c
  for c in "${CATEGORIES[@]}"; do
    IFS='|' read -r cid _ _ _ <<< "$c"
    [[ "$cid" == "$want" ]] && { echo "$c"; return 0; }
  done
}
cat_count() { echo "${#CATEGORIES[@]}"; }
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

# ---------------- defaults + selection ----------------
RECOMMENDED=("base" "hypr" "kitty" "shell")

contains() { local n="$1"; shift; local x; for x in "$@"; do [[ "$x" == "$n" ]] && return 0; done; return 1; }

SELECTED=()
if [[ -n "$ONLY" ]]; then
  IFS=',' read -r -a want <<< "${ONLY/recommended/${RECOMMENDED[*]// /,}}"
  for id in "${want[@]}"; do
    [[ -z "$id" ]] && continue
    if [[ -n "$(cat_id "$id")" ]]; then
      SELECTED+=("$id")
    else
      warn "unknown category '$id' (see --list) — ignored"
    fi
  done
else
  # interactive multi-select; bad input is re-asked, not guessed at
  while true; do
    printf '  Pick numbers (space or comma separated), "all", or press Enter for the default: '
    IFS= read -r pick
    pickx="$(printf '%s' "$pick" | tr ',' ' ')"
    if [[ -z "${pickx// /}" ]]; then SELECTED=(${RECOMMENDED[@]}); break; fi
    if [[ "${pickx,,}" == "all" ]]; then
      for c in "${CATEGORIES[@]}"; do SELECTED+=("${c%%|*}"); done; break
    fi
    nr="$(cat_count)"
    bad=0; cur=()
    for tok in $pickx; do
      if [[ "$tok" =~ ^[0-9]+$ ]] && (( tok >= 1 && tok <= nr )); then
        cur+=("$(cat_id_at "$tok")")
      else
        bad=1; break
      fi
    done
    if (( bad == 0 )); then SELECTED=("${cur[@]}"); break; fi
    warn "not a valid selection: '$pick' — enter numbers 1-$nr, 'all', or nothing for the default"
  done
fi

if [[ ${#SELECTED[@]} -eq 0 ]]; then
  echo
  ok "nothing selected — nothing to do"
  exit 0
fi

cat_id_at() { # $1 = 1-based index -> category id
  local i=$1 c
  for c in "${CATEGORIES[@]}"; do
    (( i-- == 0 )) && { echo "${c%%|*}"; return 0; }
  done
}

# ---------------- run ----------------
printf '  Will install: %s\n\n' "${SELECTED[*]}"
if [[ $DRY_RUN -eq 0 ]]; then
  mkdir -p "$BACKUP_ROOT/backups"
  : > "$MANIFEST.tmp"
fi

for id in "${SELECTED[@]}"; do
  printf '\033[1;35m▸ %s\033[0m\n' "$id"
  if "apply_$id"; then
    INSTALLED+=("$id")
    ok "$id done"
  else
    FAILED+=("$id")
    warn "$id FAILED — see the messages above (nothing else was reverted)"
  fi
  echo
done

if [[ $DRY_RUN -eq 0 && ${#INSTALLED[@]} -gt 0 ]]; then
  mv "$MANIFEST.tmp" "$MANIFEST"
fi

# ---------------- recap ----------------
printf '\n  ── recap ──\n'
printf '  installed : %s\n' "${INSTALLED[*]:-<none>}"
if [[ ${#FAILED[@]} -gt 0 ]]; then
  printf '  FAILED    : %s\n' "${FAILED[*]}"
fi
if [[ $DRY_RUN -eq 0 && ${#INSTALLED[@]} -gt 0 ]]; then
  printf '  backups   : %s\n' "$BACKUP_ROOT/backups/$TIMESTAMP"
  printf '  manifest  : %s\n' "$MANIFEST"
fi
printf '\n'

# copy-paste reprompt for the following machines
if [[ $DRY_RUN -eq 0 && ${#SELECTED[@]} -gt 0 ]]; then
  printf '  Reproduce exactly this on another machine with:\n\n'
  printf '    bash <(curl -fsSL https://raw.githubusercontent.com/%s/%s/main/bootstrap.sh) --only=%s\n\n' \
    "$GITHUB_USER" "$REPO_NAME" "$(printf '%s\n' "${SELECTED[@]}" | paste -sd,)"
  printf '  Set this box to pull updates every 24h with:\n\n'
  printf '    bash $REPO_ROOT/install.sh --yes autosync,hypr,kitty,shell\n\n'
fi
