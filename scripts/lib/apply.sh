#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# scripts/lib/apply.sh - the per-category work functions.
#
# Sourced by install.sh. Each apply_* function prints what it will do, validates
# preconditions, backs up what it will touch (timestamped), applies, then reports
# success, so a failure at any point leaves a recoverable state and says so.
#
# All configuration removal under $HOME is layered:
#   backups/<TS>/      - timestamped copy of what was displaced
#   manifest.txt       - one line per installed path, used by --uninstall
# ---------------------------------------------------------------------------
set -euo pipefail

BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.local/state/hypr-arch-setup}"
TIMESTAMP="${TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
MANIFEST="$BACKUP_ROOT/manifest.txt"
FAILED=()
INSTALLED=()

plan() { printf '        → %s\n' "$*"; }
run() { # execute, or print in dry-run
  if [[ $DRY_RUN -eq 1 ]]; then printf '        $ %s\n' "$*"; else "$@"; fi
}

backup_for() {
  # $1 = path that may be displaced; prints nothing, records the path.
  local target="$1"
  [[ -e "$target" ]] || return 0
  local dest
  dest="$BACKUP_ROOT/backups/$TIMESTAMP/$(echo "$target" | sed "s#^$HOME/##; s#/#–#g")"
  mkdir -p "$(dirname "$dest")"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '        (would back up %s -> %s)\n' "$target" "$dest"
    return 0
  fi
  rsync -a "$target" "$dest/" 2>/dev/null && printf '%s\n' "$dest" || true
}

# Copy a directory tree into place, displacing (and backing up) an existing one.
#   install_tree <src-in-repo> <dest-absolute> [rsync excludes...]
install_tree() {
  local src="$1" dst="$2"; shift 2
  [[ -d "$src" ]] || { warn "missing in repo: $src"; return 1; }
  if [[ -e "$dst" && ! -d "$dst" ]]; then
    warn "$dst exists and is not a directory — leaving it alone"; return 1
  fi
  local b=""
  if [[ -d "$dst" ]]; then
    b="$(backup_for "$dst")"
    plan "backup $dst -> ${b:-$BACKUP_ROOT/backups/$TIMESTAMP}"
  fi
  run mkdir -p "$dst"
  local ex=()
  for p in "$@"; do ex+=("--exclude=$p"); done
  run rsync -a "${ex[@]}" "$src/" "$dst/"
  printf '%s|dir|%s|%s\n' "$dst" "$src" "${b:-}" >> "$MANIFEST"
  ok "installed $dst"
}

# Copy one file into place with a timestamped sibling backup.
#   install_file <src-in-repo> <dest-absolute> [mode]
install_file() {
  local src="$1" dst="$2" mode="${3:-}"
  [[ -f "$src" ]] || { warn "missing in repo: $src"; return 1; }
  local b=""
  if [[ -e "$dst" ]]; then
    b="$dst.backup-$TIMESTAMP"
    plan "backup $dst -> $b"
    run cp -a "$dst" "$b"
  fi
  run mkdir -p "$(dirname "$dst")"
  run cp -a "$src" "$dst"
  [[ -n "$mode" ]] && run chmod "$mode" "$dst"
  printf '%s|file|%s|%s\n' "$dst" "$src" "${b:-}" >> "$MANIFEST"
  ok "installed $dst"
}

record_unit() { # $1 unit dir, $2 unit names...
  local d="$1"; shift
  for u in "$@"; do printf '%s|unit|%s|\n' "$d/$u" "$u" >> "$MANIFEST"; done
}

need_paru() {
  have paru && return 0
  have yay && { warn "using yay instead of paru"; return 0; }
  say "installing paru from the AUR"
  if [[ $DRY_RUN -eq 1 ]]; then plan "git clone paru -> /tmp && makepkg -si"; return 0; fi
  local tmp; tmp="$(mktemp -d)"
  git clone --quiet --depth 1 https://aur.archlinux.org/paru.git "$tmp/paru"
  ( cd "$tmp/paru" && makepkg -si --noconfirm )
  rm -rf "$tmp"
  have paru || die "paru installation failed — install an AUR helper manually and re-run"
}

aur_install() {
  local pkgs=("$@") helper=paru
  have paru || have yay || need_paru
  have paru || helper=yay
  [[ ${#pkgs[@]} -eq 0 ]] && return 0
  if [[ $DRY_RUN -eq 1 ]]; then plan "$helper -S --needed --noconfirm ${pkgs[*]}"; return 0; fi
  "$helper" -S --needed --noconfirm "${pkgs[@]}"
}

# ---------------- category 1: base ----------------
apply_base() {
  local missing=()
  for b in git rsync curl base-devel paru; do
    if [[ "$b" == "base-devel" ]]; then
      pacman -Qg base-devel >/dev/null 2>&1 || missing+=("base-devel")
    else
      have "$b" || missing+=("$b")
    fi
  done
  if [[ ${#missing[@]} -eq 0 ]]; then ok "core tooling already present"; return 0; fi
  say "installing: ${missing[*]}"
  if [[ $DRY_RUN -eq 1 ]]; then plan "sudo pacman -S --needed ${missing[*]}"; return 0; fi
  local pkg=()
  for m in "${missing[@]}"; do [[ "$m" == "paru" ]] || pkg+=("$m"); done
  [[ ${#pkg[@]} -gt 0 ]] && sudo pacman -S --needed --noconfirm "${pkg[@]}"
  need_paru
}

# ---------------- category 2: hypr ----------------
apply_hypr() {
  local dst="$HOME/.config/hypr"
  install_tree "$REPO_ROOT/config/hypr" "$dst" ".idea/*" "dots-archive/*" "*.bak*"

  local want=(hyprland hyprpaper hypridle hyprlock hyprsunset hyprcursor
              xdg-desktop-portal-hyprland mpvpaper rofi-wayland wlogout wallust swaync
              kitty thunar polkit-gnome network-manager-applet brightnessctl playerctl
              pavucontrol grim slurp swappy wl-clipboard cliphist qt5-wayland qt6-wayland
              imv jq python-pywal)
  local add=()
  for p in "${want[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || add+=("$p"); done
  if [[ ${#add[@]} -gt 0 ]]; then
    say "hypr: ${#add[@]} package(s) not installed"
    run sudo pacman -S --needed --noconfirm "${add[@]}" || warn "some hypr packages failed (AUR-only entry?) — continuing"
  fi

  if [[ "$HOME" != "$SOURCE_HOME" && $DRY_RUN -eq 0 ]]; then
    say "rewriting $SOURCE_HOME -> $HOME in hypr configs"
    grep -rl --include='*.conf' --include='*.sh' --include='*.py' "$SOURCE_HOME" "$dst" 2>/dev/null \
      | while read -r f; do rewrite_home_paths "$f"; done
  fi
  neutralize_monitors "$dst/configs/monitors.conf" "$dst/configs/workspaces.conf"
  if ! nvidia_present; then
    warn "no NVIDIA GPU detected — stripping NVIDIA-only env lines"
    strip_nvidia_env "$dst/configs/ENVariables.conf"
    strip_nvidia_env "$dst/UserConfigs/ENVariables.conf"
  fi
}

# ---------------- category 3: kitty ----------------
apply_kitty() {
  local dst="$HOME/.config/kitty"
  install_tree "$REPO_ROOT/config/kitty" "$dst"
  install_tree "$REPO_ROOT/assets/themes" "$dst/themes"
  if [[ ! -d "$dst/kitty-themes" && $DRY_RUN -eq 0 ]]; then
    warn "no kitty-themes/ dir — commenting out the Blazer include so kitty still starts"
    sed -i -E 's#^include \./kitty-themes/Blazer\.conf#\# &#' "$dst/kitty.conf"
  fi
  pacman -Qq kitty >/dev/null 2>&1 || run sudo pacman -S --needed --noconfirm kitty
  ok "kitty ready — try: kitty --config $dst/kitty.conf"
}

# ---------------- category 4: shell ----------------
apply_shell() {
  local dst="$HOME"
  install_file "$REPO_ROOT/home/.zshrc"    "$dst/.zshrc"
  install_file "$REPO_ROOT/home/.p10k.zsh" "$dst/.p10k.zsh"
  if [[ ! -e "$dst/.bashrc" ]] || grep -q 'hypr-arch-setup' "$dst/.bashrc" 2>/dev/null; then
    install_file "$REPO_ROOT/home/.bashrc" "$dst/.bashrc"
  else
    warn "$dst/.bashrc already customised — left alone (repo copy: home/.bashrc)"
  fi
  if [[ "$HOME" != "$SOURCE_HOME" && $DRY_RUN -eq 0 ]]; then
    rewrite_home_paths "$dst/.zshrc"
  fi

  local want=(zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting
              zsh-theme-powerlevel10k-git oh-my-zsh-git fzf bat broot zoxide thefuck atuin)
  local add=()
  for p in "${want[@]}"; do pacman -Qq "$p" >/dev/null 2>&1 || add+=("$p"); done
  [[ ${#add[@]} -gt 0 ]] && run aur_install "${add[@]}"
  ok "zsh + p10k installed (change your shell with: chsh -s /usr/bin/zsh)"
}

# ---------------- category 5: ags ----------------
apply_ags() {
  local dst="$HOME/.config/ags"
  install_tree "$REPO_ROOT/assets/ags2-shell" "$dst"

  local add=()
  for p in aylurs-gtk-shell libastal-4-git libastal-git libastal-gjs-git libastal-io-git \
           libastal-tray-git gjs gtk4 gtk4-layer-shell; do
    pacman -Qq "$p" >/dev/null 2>&1 || add+=("$p")
  done
  if [[ ${#add[@]} -gt 0 ]]; then
    say "ags: ${#add[@]} package(s) not installed"
    run aur_install "${add[@]}" || warn "ags dependency install failed — the shell will not run until fixed"
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    plan "ags types -d $dst -u"
  else
    have ags && ( cd "$dst" && ags types -d . -u 2>/dev/null && ok "regenerated @girs/" ) \
      || warn "ags types failed (harmless if you don't edit the shell)"
  fi

  install_ags_unit
}

install_ags_unit() {
  local udir="$HOME/.config/systemd/user"
  mkdir -p "$udir"
  cat > "$udir/ags2-shell.service" <<EOF
[Unit]
Description=AGS2 desktop shell (bar + launcher + popups)
After=graphical-session-pre.target graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/ags
Restart=on-failure
RestartSec=3
PassEnvironment=DISPLAY WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_SESSION_TYPE XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS

[Install]
WantedBy=graphical-session.target
EOF
  record_unit "$udir" ags2-shell.service
  run systemctl --user daemon-reload
  run systemctl --user enable ags2-shell.service
  ok "ags2-shell.service installed (enable only on Hyprland sessions)"
}

# ---------------- category 6: fonts ----------------
apply_fonts() {
  local dst="$HOME/.local/share/fonts"
  install_tree "$REPO_ROOT/assets/fonts" "$dst"
  run fc-cache -f "$dst"
  ok "fonts installed — if kitty looks wrong, run: fc-cache -f && fc-list | grep -i fantasque"
}

# ---------------- category 7: cursors ----------------
apply_cursors() {
  local dst="$HOME/.icons"
  install_tree "$REPO_ROOT/assets/icons/Bibata-Modern-Ice" "$dst/Bibata-Modern-Ice"
  [[ -f "$REPO_ROOT/assets/icons/default/index.theme" ]] \
    && install_file "$REPO_ROOT/assets/icons/default/index.theme" "$dst/default/index.theme"
  if have hyprctl; then
    run hyprctl setcursor Bibata-Modern-Classic 16
    plan "gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic (needs gsettings)"
    have gsettings && run gsettings set org.gnome.desktop.interface cursor-theme Bibata-Modern-Classic \
                      && run gsettings set org.gnome.desktop.interface cursor-size 16
  fi
  ok "cursors installed"
}

# ---------------- category 8: wallpaper ----------------
apply_wallpaper() {
  local src="$REPO_ROOT/assets/wallpapers" dst="$HOME/.config/hypr/.wallpapers"
  for f in "$src"/*.mp4; do
    if [[ -f "$f" ]] && head -c 200 "$f" | grep -q 'version https://git-lfs.github.com'; then
      warn "$(basename "$f") is still an unfetched LFS pointer (assets were never pulled)"
      plan "git -C $REPO_ROOT lfs pull --include='assets/wallpapers/*' && re-run --only=wallpaper"
      return 1
    fi
  done
  install_tree "$src" "$dst"
  pacman -Qq mpvpaper >/dev/null 2>&1 || run aur_install mpvpaper
  if ! have mpv; then
    run sudo pacman -S --needed --noconfirm mpv
  fi
  ok "wallpapers in $dst — live video wallpaper: mpvpaper -f -o hwdec=auto '*' \"$dst/output_1080p_hevc_nvenc.mp4\""
}

# ---------------- category 9: pkgs ----------------
apply_pkgs() {
  local repo_list="$REPO_ROOT/etc/pkgs-explicit-repo.txt" aur_list="$REPO_ROOT/etc/pkgs-explicit-aur.txt"
  [[ -f "$repo_list" ]] || die "missing $repo_list"
  say "full package capture: $(wc -l < "$repo_list") repo + $([[ -f "$aur_list" ]] && wc -l < "$aur_list" || echo 0) AUR"
  if [[ $ASSUME -eq 0 && $DRY_RUN -eq 0 ]]; then
    confirm "Install ALL of these? (this is a big, AUR-heavy pull)" || { warn "skipped pkgs"; return 0; }
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    plan "paru -S --needed \$(grep -v '^$' $repo_list)   # repo + base-devel"
    [[ -f "$aur_list" ]] && plan "paru -S --needed \$(grep -v '^$' $aur_list)   # AUR"
    return 0
  fi
  local repo_pkgs=() aur_pkgs=()
  mapfile -t repo_pkgs < <(grep -v '^[[:space:]]*$' "$repo_list")
  [[ -f "$aur_list" ]] && mapfile -t aur_pkgs < <(grep -v '^[[:space:]]*$' "$aur_list")
  if [[ ${#repo_pkgs[@]} -gt 0 ]]; then
    paru -S --needed --noconfirm --repo "${repo_pkgs[@]}" \
      || sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}" \
      || warn "some repo packages failed — review the log"
  fi
  if [[ ${#aur_pkgs[@]} -gt 0 ]]; then
    local helper=paru; have paru || helper=yay
    "$helper" -S --needed --noconfirm "${aur_pkgs[@]}" || warn "some AUR packages failed — review the log"
  fi
  ok "package set applied"
}

# ---------------- category 10: 24h auto-sync ----------------
apply_autosync() {
  local repo_dir="${HYPR_SETUP_DIR:-$HOME/.local/share/hypr-arch-setup}"
  local udir="$HOME/.config/systemd/user" bdir="$HOME/.local/bin"
  mkdir -p "$udir" "$bdir"

  cat > "$bdir/hypr-sync" <<SYNC
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$repo_dir"
LOG="\$HOME/.local/state/hypr-arch-setup/sync.log"
mkdir -p "\$(dirname "\$LOG")"
exec >> "\$LOG" 2>&1
echo "== \$(date -Is) sync =="
[[ -d "\$REPO_DIR/.git" ]] || { echo "no checkout at \$REPO_DIR"; exit 1; }
cd "\$REPO_DIR"
git fetch --quiet origin main
if git diff --quiet HEAD origin/main; then echo "already current"; exit 0; fi
echo "updating \$(git rev-parse --short HEAD) -> \$(git rev-parse --short origin/main)"
git pull --rebase --autostash --quiet origin main
if command -v git-lfs >/dev/null 2>&1 && [[ -d .git/lfs ]]; then git lfs pull --quiet || echo "lfs pull failed (configs still updated)"; fi
bash "\$REPO_DIR/install.sh" --yes recommended
echo "== done =="
SYNC
  chmod +x "$bdir/hypr-sync"
  ok "installed $bdir/hypr-sync"

  cat > "$udir/hypr-arch-sync.service" <<EOF
[Unit]
Description=hypr-arch-setup: pull + apply latest from GitHub

[Service]
Type=oneshot
ExecStart=$bdir/hypr-sync
EOF
  cat > "$udir/hypr-arch-sync.timer" <<'EOF'
[Unit]
Description=hypr-arch-setup: pull + apply latest every 24h

[Timer]
OnCalendar=*-*-* 00:00:00
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF
  record_unit "$udir" hypr-arch-sync.service hypr-arch-sync.timer
  run systemctl --user daemon-reload
  run systemctl --user enable --now hypr-arch-sync.timer
  say "follower timer installed: see 'systemctl --user list-timers hypr-arch-sync.timer'"
}