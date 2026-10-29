# .Hyprland-Dots archive

The `.Hyprland-Dots/` repository (JaKooLit/Hyprland-Dots) was removed from this workspace.
Active Hyprland boot/config uses `.config/hypr/` (not `.Hyprland-Dots/config/hypr/`).

- Active session: `/etc/sddm.conf` → `Session=hyprland-uwsm.desktop`
- Active main config: `.config/hypr/hyprland.conf`
- Active sources: `.config/hypr/configs/` + `.config/hypr/UserConfigs/`
- Active boot scripts: `.config/hypr/initial-boot.sh`

Copied here for reference/update history only:
- `scripts/` — library/update helpers
- `update-dots.sh`, `copy.sh` — repo management scripts
- `archive/release.sh`, `archive/upgrade.sh`
- `config/hypr/*.conf` — older reference configs (Jan 19 versions)
- `CHANGELOG.md`, `README.md`, `COMMIT_MESSAGE_GUIDELINES.md`, `CONTRIBUTING.md`

Do not edit these expecting boot changes — boot reads `.config/hypr/hyprland.conf`.
