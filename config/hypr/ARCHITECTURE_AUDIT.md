# System Architecture Verification — Post `.Hyprland-Dots/` Removal

**Verified:** 2026-09-10 (current session)
**Status:** ARCHITECTURE STABLE — all boot/logging/config paths verified

---

## 1. Boot Chain Simulation (Verified Evidence)

```
/etc/sddm.conf
  [Autologin]
  User=gfardad
  Session=hyprland-uwsm.desktop  ← active session

/usr/share/wayland-sessions/hyprland-uwsm.desktop
  Exec=uwsm start -e -D Hyprland hyprland.desktop

/usr/bin/uwsm  (exists: YES, binary verified)
  loads .config/uwsm/env (exists: YES)
    env = LIBVA_DRIVER_NAME=nvidia
    env = XDG_SESSION_TYPE=wayland
    env = __GLX_VENDOR_LIBRARY_NAME=nvidia

.config/hypr/hyprland.conf (exists: YES, 90 lines, intact)
  sources:
    .config/hypr/configs/Keybinds.conf
    .config/hypr/configs/ENVariables.conf
    .config/hypr/configs/SystemSettings.conf
    .config/hypr/configs/WindowRules.conf
    .config/hypr/configs/Startup_Apps.conf
    .config/hypr/UserConfigs/UserKeybinds.conf
    .config/hypr/UserConfigs/UserDecorations.conf
    .config/hypr/UserConfigs/01-UserDefaults.conf
    .config/hypr/UserConfigs/UserAnimations.conf
    .config/hypr/UserConfigs/UserSettings.conf
    .config/hypr/monitors.conf  (exists: 4 monitors, 240Hz verified)
    .config/hypr/workspaces.conf (exists)

exec-once in .conf:
  .config/hypr/initial-boot.sh  (exists; .initial_startup_done marker exists → won't rerun)
  hyprctl output create headless SUNSHINE; $HOME/.config/hypr/scripts/wallpaper.sh
  ags
  # REMOVED 2026-10-11: /home/gfardad/.local/bin/fix-4k240.sh --quiet  (deleted — monitors.conf pins 240.02+bitdepth,10)
  # REMOVED 2026-10-11: .../pipx/venvs/hypr-session/bin/hypr-session restore --wait  (removed with hypr-session dependency)
```

**Conclusion:** Boot chain intact. `.Hyprland-Dots/` never in boot path.

---

## 2. What Was Removed / Changed

- `.Hyprland-Dots/` directory removed (was separate git repo, inode 1208500)
- Archive saved: `.config/hypr/dots-archive/` (23 + docs + scripts + older configs)
- `.Hyprland-Dots` reference notes removed from active boot configs and replaced with archive reference

---

## 3. References Updated (Active Paths Only)

| File | Change |
| .config/hypr/hyprland.conf | Unchanged (main config intact) |
| .config/hypr/scripts/KooLsDotsUpdate.sh | Points to `.config/hypr/dots-archive/`; note added |
| .config/hypr/scripts/KeyHints.sh | References `.config/hypr/dots-archive/NOTE_ARCHIVED.md` |
| .config/hypr/UserConfigs/00-Readme | Note `.Hyprland-Dots/` removed; active config path noted |
| .config/hypr/DISPLAY_4K240_RUNBOOK.md | Note at top: `.Hyprland-Dots/` removed; active `.config/hypr/` |
| .dotfiles/README.md | Note `.Hyprland-Dots/` removed |
| .openclaw/workspace/AGENTS.md | Note active `.config/hypr/` and archive path |
| .config/hypr/configs/Keybinds.conf | Comment updated |
| .config/hypr/hyprlock.conf / hyprlock-2k.conf | References updated |
| .config/hypr/v2.3.18 | Note updated |

---

## 4. System Services Verified

- `dsh-web.service` (`start-backend.sh`): active, port 3080 listening (`127.0.0.1:3080`)
- `dsh-proxy.service` (`dsh-proxy.js`): active, port 3082 listening (`0.0.0.0:3082`)
- `tailscale` (serve): `/` proxied to `http://192.168.1.200:3082` (tailnet access verified)
- `sddm`: configured for autologin (`User=gfardad`, `Session=hyprland-uwsm.desktop`)
- `hypr-session`: **REMOVED 2026-10-11** — the `exec-once ... hypr-session restore --wait` line is gone

---

## 5. Config Integrity Check

- `.config/hypr/hyprland.conf`: intact, 90 lines
- `.config/hypr/hyprland.lua`: **REMOVED 2026-10-11** — archived as `dots-archive/dead-files-2026-10-11/hyprland.lua.bak`.
  Hyprland 0.56.2 has no Lua loader, so `packages/` was already inert; the whole `packages/` directory
  (12 `.lua` files) plus `configs/Startup_Apps.lua` is now archived there too. Do **not** restore the
  loader — those files still carry dead values (`HDMI-A-4`, `HYPRCURSOR_SIZE 24`, `Bibata-Modern-Ice`)
  that would silently fight the current `.conf` config.
- `.config/hypr/configs/*.conf`: 7 config files present
- `.config/hypr/UserConfigs/*.conf`: 11 user config files present
- `.config/hypr/scripts/*.sh`: script library intact (`KooLsDotsUpdate.sh` updated)
- `.config/hypr/initial-boot.sh`: unchanged (runs once, `.initial_startup_done` exists)
- `.config/hypr/monitors.conf`: 4 monitors (DP-2 / HDMI-A-5 / DP-3 / SUNSHINE headless), 240Hz DP-2 verified (`3840x2160@240.02 + bitdepth,10`, straight from `monitors.conf` — no runtime band-aid)
- `.config/hypr/workspaces.conf`: exists
- No broken symlinks in `.config/hypr/`
- No missing files referenced by `.conf` sources

---

## 6. Security / Notice

- `.Hyprland-Dots/` removal does NOT expose any secrets.
- `.Hyprland-Dots/` contained only dotfiles/configs (no credentials).
- `.config/uwsm/env` preserved with NVIDIA env vars.
- Active boot does not reference removed directory.
- Archive preserved for historical reference.

---

## 7. Final Status

```
Boot session:     hyprland-uwsm.desktop (UWSM-managed)
Active .conf:     .config/hypr/hyprland.conf
Active sources:    .config/hypr/configs/ + UserConfigs/
Boot scripts:      initial-boot.sh + ags + wallpaper.sh (from hyprland.conf, after SUNSHINE creation)
Archive:           .config/hypr/dots-archive/
System stable:     YES — all services active, ports listening, boot chain intact
```

**Agent note:** `.openclaw/workspace/AGENTS.md` updated with workspace config note (`.config/hypr/` active, `.Hyprland-Dots/` removed, archive at `.config/hypr/dots-archive/`).
