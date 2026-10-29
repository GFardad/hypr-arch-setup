# hypr-arch-setup

My complete Arch Linux / Hyprland rice — **settings, hyprland config, shell,
kitty, ags2-shell, wallpapers, fonts, cursors and my full installed package list**
— versioned on GitHub and installed from a single one-line command.

## One-line install (on a fresh Arch machine)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GFardad/hypr-arch-setup/main/bootstrap.sh)
```

That clones this repo and runs `install.sh` interactively. It is hardware-aware:
monitor/workspace configs, NVIDIA-only env and absolute `/home/gfardad` paths are
all neutralised or rewritten so they don't break a machine that isn't this one.

### Reproduce exactly what I run, unattended

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GFardad/hypr-arch-setup/main/bootstrap.sh) \
  --only=base,hypr,kitty,shell,fonts,cursors,wallpaper,ags,autosync --yes
```

## What gets installed (the 10 categories)

| id        | what                                                             | default |
|-----------|------------------------------------------------------------------|---------|
| base      | git, rsync, curl, base-devel, paru (AUR helper)                  | on      |
| hypr      | hyprland + deps, `~/.config/hypr` (hardware-adapted)             | on      |
| kitty     | terminal + my config + dracula theme                             | on      |
| shell     | zsh, oh-my-zsh, powerlevel10k, `~/.zshrc`/`~/.p10k.zsh`          | on      |
| ags       | ags2-shell bar/launcher + astal deps                             | off     |
| fonts     | SF Pro Nerd fonts (124M)                                         | off     |
| cursors   | Bibata-Modern-Ice + default theme                                | off     |
| wallpaper | live video wallpapers (342M, via mpvpaper)                       | off     |
| pkgs      | my **entire** `pacman -Qqe`/`-Qqm` capture (160 AUR + 475 repo)  | off     |
| autosync  | 24h systemd timer that pulls + re-applies the latest config      | off     |

Big assets (fonts, wallpapers, mp4s) are tracked with **Git LFS** — the clone
downloads small pointers; the installer fetches real bytes only for the
categories you pick.

`--only=base,hypr,kitty,shell` is the fast, safe "get a working desktop" path.
Add `fonts,cursors` for a near-identical look. `pkgs` and `wallpaper` are the
heavy ones and default off.

## Auto-sync every 24 hours

- **My machine (the source):** a systemd timer runs `scripts/capture.sh` daily —
  snapshots my live configs/wallpapers/fonts/package list into the repo, commits
  and pushes to GitHub.
- **Any follower machine:** enable the `autosync` category — it installs a 24h
  timer that `git pull`s the repo, then re-runs `install.sh` so it always
  tracks my latest config.

```bash
# on the source machine (you, after installing)
systemctl --user enable --now hypr-arch-capture.timer
systemctl --user list-timers | grep hypr-arch

# on any follower machine
bash install.sh --only=autosync
```

### Manual run instead

```bash
./scripts/capture.sh          # snapshot + push my current state (source)
~/.local/bin/hypr-sync        # pull + apply latest (follower)
```

## Reverting

Everything the installer touches is backed up first:

- displaced trees → `~/.local/state/hypr-arch-setup/backups/<timestamp>/`
- displaced single files → `.backup-<timestamp>` sibling
- a `manifest.txt` records every path the installer wrote

## What's in the repo

```
assets/
  ags2-shell/   patched ags2-shell source (git LFS-free; @girs/ regenerated at install)
  fonts/        SF Pro Nerd (.otf, LFS)
  icons/        Bibata-Modern-Ice + default theme
  wallpapers/   live video wallpapers (.mp4, LFS)
  themes/       dracula kitty theme
config/
  hypr/         JaKooLit-derived hyprland config (hardware-adapted at install)
  kitty/        terminal config + themes
  zellij/       zellij layout
etc/
  pkgs-*.txt    pacman explicit + foreign captures (repo and AUR)
home/
  .zshrc .p10k.zsh .bashrc
scripts/
  bootstrap.sh   one-line entry point (clone + exec install.sh)
  capture.sh     master: snapshot + commit + push
  install.sh     interactive installer / re-applier
  lib/           shared helpers (common.sh, apply.sh)
systemd/         capture + sync unit/timer files (also written by installer)
```

## Requirements

- Arch Linux (or an `arch-release`-based distro)
- an AUR helper available to the installing user (paru auto-installs if missing)
- git + curl

Everything under `$HOME` is displaced with timestamped backups, so it's safe to
re-run as often as you like. Installer never touches system packages without a
clear `sudo pacman` line, and only installs the categories you choose.