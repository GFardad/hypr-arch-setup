> **Active config note:** Boot uses `.config/hypr/` (not `.Hyprland-Dots/`). `.Hyprland-Dots/` removed; archive saved in `.config/hypr/dots-archive/`.
> Session: `/etc/sddm.conf` → `hyprland-uwsm.desktop` → `.config/hypr/hyprland.conf`.
>
> **2026-10-11 update:** `~/.local/bin/fix-4k240.sh` (§9) was DELETED and its exec-once removed —
> the rule in `monitors.conf` permanently pins the 4K panel to `3840x2160@240.02 + bitdepth,10`,
> so the band-aid is obsolete (do not re-add it). The Sunshine dummy is NO LONGER a kernel-EDID
> `HDMI-A-4`; it is now a Hyprland headless output named `SUNSHINE` (exec-once in hyprland.conf +
> `monitor=SUNSHINE,disable` in monitors.conf). §5's kernel-cmdline EDID instructions are historical.
>
> **Canonical `monitors.conf` (2026-10-23) — EDID-description based, so connector names are irrelevant:**
> ```
> monitor=desc:ASUSTek COMPUTER INC PG32UCDM T4LMQS021303,3840x2160@240.02,1920x1080,1,bitdepth,10,vrr,0
> monitor=desc:ChangHong Electric Co.Ltd GDM-225JN 0000000000001,1920x1080@60.0,0x2160,1,vrr,0
> monitor=desc:ChangHong Electric Co.Ltd GDM-275LN 0000000000001,1920x1080@75.0,5760x2160,1,vrr,0
> monitor=SUNSHINE,disable
> ```
> `~/.config/hypr/scripts/monitors-stream.sh list` prints which `DP-x` / `HDMI-A-x` name each panel
> currently has. **Any name-based rule you find further down this document is from the old era.**
> All three physical monitors are **bottom-aligned** (y=2160, bottoms y=3240); every `1920x0`
> / `0x1080` position in the sections below is from the older top-aligned era. Pasting those
> would move your displays. Live truth = `hyprctl monitors`.

**Date:** 2026-09-08  
**Author:** Fix session — Hyprland 0.56.2 / aquamarine 0.15.0 / nvidia-open 610.57.04 / kernel 7.2.2-arch1-1  
**Current state: WORKING** — `DP-2` at `3840x2160@240.016` verified via `hyprctl monitors` + `wlr-randr`

---

## TL;DR for the next breakage

Your 4K240 is whichever connector currently carries the EDID `ASUSTek … PG32UCDM …` — **never a fixed name** (§1). Run this one line:

```bash
hyprctl keyword monitor "desc:ASUSTek COMPUTER INC PG32UCDM T4LMQS021303,3840x2160@240.02,1920x1080,1,bitdepth,10,vrr,0" && hyprctl monitors | grep -A2 -i ASUSTek
```

If it says `3840x2160@240.016` you're done. If it says `120.00`, keep reading. To restore the whole
layout (all three panels + workspace re-homing) in one shot: `~/.config/hypr/scripts/monitors-stream.sh off`.

Alternative (equivalent, name-independent):
```bash
ASUS_NAME=$(hyprctl monitors | awk '/^Monitor /{n=$2} /ASUSTek/{print n; exit}')
wlr-randr --output "$ASUS_NAME" --mode 3840x2160@240.016Hz
```

---

## 1. Monitor Identity Map — DO NOT confuse these again

> ⚠️ **2026-10-22 — the `DP-2` / `DP-3` / `HDMI-A-5` names below are ONE BOOT'S naming and are
> not authoritative.** On this two-GPU box the kernel's connector numbers come from a
> system-wide counter filled in **driver registration order**, which changes between boots
> (see §8 for the dated history). On 2026-10-22 the very same panels appeared as `DP-1` / `DP-2` / `HDMI-A-2`.
> The *panel identities* in the table are correct; the *names* are not a stable key.
> Everything in `monitors.conf`, `workspaces.conf` and the wallpaper/streaming scripts now
> binds by **EDID description** instead. Never re-create name-based rules; and let
> `nwg-displays` rewrite `monitors.conf` only with its "Use description" toggle ON (it then writes
> `monitor=desc:…` rules like these — with the toggle off it regenerates the name-based bug).

### Current mapping (validated 2026-10-22) — key on the description, not the name

| Panel | Name that boot | Name the old era used | Stable key (EDID description) |
|---|---|---|---|
| **Main 4K240** (ASUS PG32UCDM) | `DP-1` | `DP-2` | `ASUSTek COMPUTER INC PG32UCDM T4LMQS021303` |
| 1080p60 (ChangHong GDM-225JN, HDMI) | `HDMI-A-2` | `HDMI-A-5` | `ChangHong Electric Co.Ltd GDM-225JN 0000000000001` |
| 1080p75 (ChangHong GDM-275LN, DP) | `DP-2` | `DP-3` | `ChangHong Electric Co.Ltd GDM-275LN 0000000000001` |

⚠️ Note the trap: `DP-2` exists in **both** eras but names a **different physical panel** now.
An old name-based rule ("`DP-2` = 4K240") is why two panels stopped behaving.

### Historical identity table (names = old era)

| What it *is* | Kernel name (`hyprctl`/`wlr-randr`/`/sys/class/drm`) | Vendor / EDID | Physical capability | Evidence |
|---|---|---|---|---|
| **Your main 4K 240Hz** | **`DP-2`** | `ASUSTek PG32UCDM` `AUS 13042` `S/N T4LMQS021303` `700x400mm` | `3840x2160 @ 240.016Hz` (DisplayID, DSC, 10bpc, 48-240Hz, max dotclock 2340 MHz, HDR/BT2020) | `edid-decode /sys/class/drm/card2-DP-2/edid` → `DisplayID: 3840x2160 240.016 2332MHz` + `modetest -M nvidia-drm` mode #1 = `3840x2160 240.02` |
| Secondary 1080p 75Hz | `DP-3` | `ChangHong GDM-275LN` `CHD 624` `600x330mm` | **1080p 75Hz MAX.** `Display Range Limits: 48-75Hz V, 85kHz H, max dotclock 200 MHz`. No 4K mode advertised. | `edid-decode /sys/class/drm/card2-DP-3/edid` — zero `3840x2160` in `/sys/class/drm/card2-DP-3/modes` |
| Secondary 1080p 60Hz | `HDMI-A-5` | `ChangHong GDM-225JN` `CHD 544?` | 1080p60 | `edid-decode /sys/class/drm/card2-HDMI-A-5/edid` |
| **Sunshine dummy** (headless streaming) | `HDMI-A-4` | `The Linux Foundation 1080p60` `LNX 0` — FAKE EDID from file | 1080p60 only, 59-61Hz, max dotclock 180 MHz | File `/lib/firmware/edid/sunshine-1080p60.bin` (128 bytes), forced via kernel cmdline |

**Rule:** `DP-3` will **never** do 4K. Setting it to 4K makes the driver reject the mode and fall back to `1920x1080@74-75`. That's not a cable failure.

---

## 2. Root Causes Found (why it was stuck at 120)

1. **Wrong target.** You were changing `DP-3` (1080p75 panel) expecting 4K240. Driver correctly fell back.
2. **Config cap.** `~/.config/hypr/monitors.conf` (generated by `nwg-displays` on `2026-09-07 20:02:17`) had:
   ```ini
   monitor=DP-2,3840x2160@120.0,1920x0,1,vrr,0
   ```
   So every boot forced 120 even though the panel advertises 240.
3. **DSC + bitdepth requirement.** `4K@240` on this panel + `RTX 3060 Ti` needs **Display Stream Compression** and **`bitdepth,10`** with an exact timing. `hyprctl keyword monitor <4K-panel>,3840x2160@240,…` *without* `bitdepth,10` fails the kernel `ATOMIC_TEST_ONLY` check:
   ```
   atomic drm request: failed to commit: Invalid argument, flags: ATOMIC_ALLOW_MODESET ATOMIC_TEST_ONLY
   drm: Modesetting DP-2 with 3840x2160@120.00Hz   # fallback
   GBM: Failed to allocate a GBM buffer: format XR30 isn't supported
   ```
   The fix needs the exact mode string `240.02` (Hyprland) / `240.016` (wlr-randr), not `240`.
4. **ABI mismatch (secondary).** `Hyprland 0.56.2 built against Aquamarine 0.14.0, system has 0.15.0` — seen in `hyprctl version`. Causes noisy `Device or resource busy` / `Cannot commit when a page-flip is awaiting` but didn't block 240 by itself.
5. **Sunshine dummy.** Created by the agent you asked to make Sunshine display your screens remotely. **Not the cause** of the 120 cap, but it occupies CRTC 200 + shows as 4th monitor and confuses tooling. See §5.

---

## 3. Current Working Config (snapshot 2026-09-08 06:52, verified)

### `~/.config/hypr/monitors.conf`
```ini
# 2026-09-08 snapshot — OBSOLETE, kept as history: generated by nwg-displays, name-based.
# The live file has been EDID-description based since 2026-10-22 (see the canonical block at the top).
monitor=HDMI-A-4,1920x1080@60.0,7680x1080,1.0,vrr,0
monitor=HDMI-A-5,1920x1080@60.0,0x1080,1,vrr,0
monitor=DP-3,1920x1080@75.0,5760x1080,1,vrr,0
monitor=DP-2,3840x2160@240.02,1920x0,1,bitdepth,10,vrr,0
```
> **Layout then:** the 1080p60 panel at `0x1080` — the 4K (then called `DP-2`) at `1920x0` — the 1080p75 panel at `5760x1080`.  
> **Layout now:** the 4K at `1920x1080`, the 1080p60 panel at `0x2160`, the 1080p75 panel at `5760x2160` (all bottom-aligned).  
> Warm spare for the 4K: `desc:…PG32UCDM…,preferred,1920x1080,1,bitdepth,10` — be explicit about 240 when it matters.

### `hyprctl monitors` proof
```
Monitor DP-2 (ID 1):
	3840x2160@240.01601 at 1920x0
```

### `wlr-randr` proof
```
DP-2 "ASUSTek COMPUTER INC PG32UCDM T4LMQS021303 (DP-2)"
  Modes:
    3840x2160 px, 240.016006 Hz   # mode #1 in modetest
```

### `modetest -M nvidia-drm` for DP-2 (connector 826 / crtc 392)
```
#1 3840x2160 240.02 3840 3888 3920 4000 2160 2163 2168 2429 2332000 flags: phsync, nvsync
#3 3840x2160 120.00 3840 3952 3984 4000 2160 2279 2284 2287 1097750
```

### Versions at fix time
```
hyprland 0.56.2-2
aquamarine 0.15.0-2  (built against 0.14.0 — mismatch)
nvidia-open-dkms 610.57.04-1
kernel 7.2.2-arch1-1
```

---

## 4. When It Breaks Again — Recovery

### Symptoms
- `hyprctl monitors | grep DP-2` shows `120.00` or `60.00` instead of `240.016`
- `xrandr --verbose` shows `1920x1080@74.91` on DP-3 (you're looking at the wrong output)
- Hyprland log (`/run/user/1000/hypr/*/hyprland.log`) shows `ATOMIC_TEST_ONLY Invalid argument` then `Modesetting DP-2 with 3840x2160@120.00Hz`

### 30-Second Fix (no reboot)
```bash
# Mode string that works: 240.02 (never "240" or "240.016").
# Address the panel by its EDID description, NOT by connector name (see §1).

# Normal session (hyprland.conf loaded):
hyprctl keyword monitor "desc:ASUSTek COMPUTER INC PG32UCDM T4LMQS021303,3840x2160@240.02,1920x1080,1,bitdepth,10,vrr,0"

# If keyword refuses with "keyword can't work with non-legacy parsers. Use eval."
# you are in a Lua-mode session — almost always because Hyprland restarted in
# --safe-mode after a crash (see §4b). Then use eval instead:
hyprctl eval 'hl.monitor({output="desc:ASUSTek COMPUTER INC PG32UCDM T4LMQS021303", mode="3840x2160@240.02", position="1920x1080", scale=1, bitdepth=10, vrr=0})'

# Verify name-independently (match the description, not the name):
hyprctl monitors | grep -iE 'Monitor |ASUSTek'

# Restore the WHOLE layout (all three panels, by description) in one shot:
~/.config/hypr/scripts/monitors-stream.sh off
```

### 4b. Hyprland came back in `--safe-mode` (no keybinds, flat default layout)
Symptom: only a handful of binds (`hyprctl binds | grep -c '^bind'` → ~3), no bar, default
decorations, monitors in a plain row at default modes, and
`hyprctl configerrors` says something like `hyprland.conf:2: unexpected symbol near '#'`.

Cause: `/usr/bin/start-hyprland` (uwsm's launcher) restarts Hyprland with **`--safe-mode`**
after an unclean exit. Safe mode **ignores `hyprland.conf`** and generates a default config,
so the session runs without your keybinds, env, autostarts or monitor rules.
Check what crashed: `ls -t ~/.cache/hyprland/hyprlandCrashReport*.txt | head -1`.

Live mitigations (no relogin needed):
- `hyprctl dispatch ...` still works.
- `hyprctl keyword ...` does **not** (`Use eval.`) — use `hyprctl eval 'hl.monitor({...})'`.
- `hl.workspace{...}` does **not** exist; workspace rules cannot be applied live.

Real fix: end the session and log back in (or `hyprctl dispatch exit` → SDDM → login).
That starts Hyprland without `--safe-mode`, so `hyprland.conf` + `monitors.conf` +
`workspaces.conf` load normally.

Known crash trigger (fixed 2026-10-22): `monitors-stream.sh on` used to disable all three
physical panels *before* the headless `SUNSHINE` output existed, leaving zero enabled
outputs → SEGV in `CInputManager::refocusLastWindow`. The script now brings `SUNSHINE` up
first and refuses to disable the last enabled output.

### If 30-Second Fix Fails — Isolate
Bandwidth/DSC tests: disable others, retry 240, restore.

```bash
# ⚠️ Panels are addressed by EDID description here — connector names shuffle between
# boots (see §1). `DP-2` is the 4K on some boots and the 1080p75 panel on others.
ASUS="desc:ASUSTek COMPUTER INC PG32UCDM T4LMQS021303"
CH275="desc:ChangHong Electric Co.Ltd GDM-275LN 0000000000001"
CH225="desc:ChangHong Electric Co.Ltd GDM-225JN 0000000000001"
HLOG="/run/user/1000/hypr/$(ls -t /run/user/1000/hypr | head -1)/hyprland.log"

# 1) Free heads (helps if CRTC/BW limited). NEVER disable them all — zero enabled
#    outputs crashed Hyprland 0.56.2 on 2026-10-22 (see §4b).
hyprctl keyword monitor "$CH225,disable"
hyprctl keyword monitor "$CH275,disable"

# 2) Lower-bandwidth sanity: 1440p240 should always work if DSC is OK
hyprctl keyword monitor "$ASUS,2560x1440@239.97,1920x1080,1,bitdepth,10,vrr,0"
hyprctl monitors | grep -A2 -i ASUSTek
# If 1440p240 works but 4K240 doesn't -> DSC / cable / link-rate issue

# 3) Back to 4K240
hyprctl keyword monitor "$ASUS,3840x2160@240.02,1920x1080,1,bitdepth,10,vrr,0"
hyprctl monitors | grep -A2 -i ASUSTek

# 4) Check log
grep -E "240|120|ATOMIC_TEST_ONLY|Modesetting|Invalid" "$HLOG" | tail -20

# 5) Restore the whole layout — safest single command (EDID-based, re-homes workspaces)
~/.config/hypr/scripts/monitors-stream.sh off
```

### Full Diagnostic (copy-paste)
```bash
echo "== monitors (descriptions included) =="; hyprctl monitors | grep -E "Monitor |description|@.*at"
echo "== locate the 4K's DRM node by EDID (name-independent) =="
for c in /sys/class/drm/card*-*/edid; do edid-decode "$c" 2>/dev/null | grep -q PG32UCDM && echo "  4K EDID path: $c"; done
echo "== EDID detail for the 4K =="; edid-decode "$(for c in /sys/class/drm/card*-*/edid; do edid-decode "$c" 2>/dev/null | grep -q PG32UCDM && echo "$c"; done | head -1)" 2>&1 | grep -E "3840x2160|DisplayID|240"
echo "== wlr-randr (match the EDID model, never the connector) =="; timeout 5 wlr-randr | grep -A20 -i "ASUSTek"
echo "== modetest modes =="; timeout 5 modetest -M nvidia-drm 2>&1 | grep -B2 -A2 "3840x2160" | head -30
echo "== current name mapping (script view) =="; ~/.config/hypr/scripts/monitors-stream.sh list
echo "== cmdline: any name-based edid_firmware left? (should be none) =="; tr ' ' '\n' < /proc/cmdline | grep -E "edid|video" || echo "  none"
echo "== hyprland log last fail =="; HLOG="/run/user/1000/hypr/$(ls -t /run/user/1000/hypr | head -1)/hyprland.log"; grep -E "Invalid argument|240.02|120.00" "$HLOG" | tail -15
echo "== aquamarine mismatch? =="; hyprctl version | grep -i aquamarine; pacman -Q hyprland aquamarine nvidia-open-dkms
```

### Live-testing the streaming cycle (`monitors-stream.sh on` / `off`)

Both halves are EDID-based and hardened (see §8), but only `off` has been exercised against the
live compositor so far. To prove `on` yourself, run it when a dropped session costs nothing —
nothing unsaved open, or just before a reboot:

```bash
# 1) record where things are now
~/.config/hypr/scripts/monitors-stream.sh list
hyprctl -j clients | jq -r '.[] | "\(.workspace.id)\t\(.class)"' | sort > /tmp/wins-before.txt

# 2) prep (streaming): SUNSHINE comes up FIRST, then the three panels go off
~/.config/hypr/scripts/monitors-stream.sh on
hyprctl monitors        # expect ONLY SUNSHINE enabled, 1920x1080@60 @0x0

# 3) undo: panels return by description, workspaces 1/2 -> 4K, 3 -> 1080p75, 4 -> 1080p60,
#    then SUNSHINE is disabled again (its idle state, matching monitors.conf)
~/.config/hypr/scripts/monitors-stream.sh off
hyprctl monitors        # expect the 3 panels back and SUNSHINE disabled

# 4) confirm windows came home with their workspaces
hyprctl -j clients | jq -r '.[] | "\(.workspace.id)\t\(.class)"' | sort | diff - /tmp/wins-before.txt \
  && echo "layout identical"
```

**If the session ever returns with no keybinds and a default look,** uwsm restarted Hyprland in
`--safe-mode` after a crash — §4b has the recovery steps and the cause. The script no longer has that
failure mode (it enables `SUNSHINE` before disabling anything, never drops below one enabled output,
and `off` re-disables `SUNSHINE` only once a physical panel is up), but a compositor restart takes
running apps down with it — hence "nothing unsaved open".

### Common False Leads — Do NOT Do These
- **Do not use `xrandr` on Hyprland (Wayland).** `xrandr` shows a XWayland compatibility shim — `75Hz` / `59.96Hz` numbers are lies. Use `wlr-randr` / `hyprctl monitors`.
- **Do not trust connector names in any command.** They shuffle between boots: `DP-2` is the 4K panel on one boot and the 1080p75 panel on another. Resolve panels by EDID description — `~/.config/hypr/scripts/monitors-stream.sh list` prints the current mapping.
- **Do not set either 1080p panel to 4K.** Neither advertises a 4K mode; identify them by EDID (`…GDM-275LN…` / `…GDM-225JN…`), never by name.
- **Do not buy a new cable yet.** `modetest` mode #1 `2332000 kHz` + `link-status: Good` means link training is fine.
- **`nwg-displays` is only safe with its “Use description” toggle ON** (`~/.config/nwg-displays/config` → `"use-desc": true`, set 2026-10-23). With it on, Apply writes `monitor=desc:…` rules and is harmless; with it off it writes bare connector names and silently misplaces panels — which is exactly what happened on 2026-09-07 and 2026-10-20. Nothing auto-applies: `monitors.conf` is rewritten only when you press Apply, so never Apply while that toggle is off.

---

## 5. Sunshine Agent Changes — What It Did, Safe to Keep

The agent you asked to “display my displays remotely” correctly set up headless streaming, but it added state you should know about:

| File | What was added | Purpose |
|---|---|---|
| `/lib/firmware/edid/sunshine-1080p60.bin` (+ copy in `/usr/lib/firmware/edid/`) | 128-byte fake EDID `LNX 1080p60` (60Hz, 173MHz) | Fake monitor so Sunshine can encode even with no real monitor |
| `/etc/mkinitcpio.conf: FILES=(/usr/lib/firmware/edid/sunshine-1080p60.bin)` | Include EDID in initramfs | Needed for early `drm.edid_firmware` |
| `/etc/default/grub: GRUB_CMDLINE_LINUX_DEFAULT="… drm.edid_firmware=HDMI-A-4:edid/sunshine-1080p60.bin video=HDMI-A-4:e"` then baked into `/proc/cmdline` | Force `HDMI-A-4` to use fake EDID at boot | Creates `HDMI-A-4 The Linux Foundation 1080p60` as always-on output |
| `~/.config/sunshine/sunshine.conf` | `output_name=HDMI-A-4`, `capture=wlr`, `encoder=nvenc`, `av1_mode=1`, `port=47990`, `bind=0.0.0.0` | Tell Sunshine to capture `HDMI-A-4` |
| `~/.config/sunshine/apps.json: Virtual Desktop (HDMI-A-4)` | `prep-cmd: hyprctl keyword monitor DP-2,disable && … DP-3,disable && … HDMI-A-5,disable && HDMI-A-4,1920x1080@60.0` / `undo: … DP-2,3840x2160@240.02,1920x0,1,bitdepth,10 …` | **Disables your real monitors while a client is streaming** to save bandwidth. `undo` restores 240 correctly. |
| Systemd | `~/.config/systemd/user/sunshine.service` enabled, `sunshine` running since 2026-09-01 | Headless streamer |

**Is it blocking 240?** No — tested with `HDMI-A-4` disabled, 240 still required `bitdepth,10`. You can keep it. If you remove it, you lose headless streaming when all real monitors are off.

**To remove cleanly (if you want):**
```bash
# 1) Stop service
systemctl --user disable --now sunshine

# 2) Remove EDID files
sudo rm /lib/firmware/edid/sunshine-1080p60.bin /usr/lib/firmware/edid/sunshine-1080p60.bin

# 3) Remove kernel param
sudo sed -i 's/ drm.edid_firmware=HDMI-A-4:edid\/sunshine-1080p60.bin//g' /etc/default/grub
sudo sed -i 's/ video=HDMI-A-4:e//g' /etc/default/grub
sudo sed -i '/FILES=.*sunshine/d' /etc/mkinitcpio.conf  # or edit FILES=() manually

# 4) Rebuild
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg

# 5) Remove config backup (optional)
# rm ~/.config/sunshine/sunshine.conf.bak
# reboot, then HDMI-A-4 will disappear
```

**To keep it but avoid confusion:** The dummy lives at `7680x1080` far right — ignore it. Sunshine log lives at `~/.config/sunshine/sunshine.log`.

---

## 6. Prevention — Make It Stick

1. **Pin `monitors.conf`.** After fixing, either make it immutable (optional) or just remember `nwg-displays` rewrites it:
   ```bash
   # Optional: prevent silent overwrite
   chattr +i ~/.config/hypr/monitors.conf   # to edit later: chattr -i …
   ```
   Minimal safe alternative to `preferred`:
   ```ini
   monitor=DP-2,preferred,1920x0,1,bitdepth,10,vrr,0
   ```
2. **Don't use `xrandr`.** Alias away: `alias xrandr='echo "Use wlr-randr / hyprctl monitors on Hyprland"; wlr-randr'`
3. **Exact mode strings matter.** For this panel: `hyprctl` expects `240.02`, `wlr-randr` shows `240.016Hz`. `240` alone fails validation.
4. **Fix aquamarine mismatch** next `pacman -Syu`:
   ```bash
   sudo pacman -Syu   # should pull aquamarine 0.15 rebuild of hyprland
   # verify: hyprctl version | grep Aquamarine  -> built against == system has
   ```
5. **Snapshot this runbook** with your dotfiles:
   ```bash
   cp ~/DISPLAY_4K240_RUNBOOK.md ~/.config/hypr/
   ```

---

## 7. Quick Commands Cheat-Sheet

```bash
# Verify 240 is active
hyprctl monitors | grep -E "DP-2.*@"
wlr-randr | grep -A30 'DP-2 "ASUSTek'

# Force 240 (no reboot)
hyprctl keyword monitor "desc:ASUSTek COMPUTER INC PG32UCDM T4LMQS021303,3840x2160@240.02,1920x1080,1,bitdepth,10,vrr,0"

# Persist
$EDITOR ~/.config/hypr/monitors.conf  # set DP-2 line, then:
hyprctl reload

# EDID sanity
edid-decode /sys/class/drm/card2-DP-2/edid | grep -A2 "DisplayID\|3840x2160"
cat /sys/class/drm/card2-DP-2/modes | sort -u
for c in /sys/class/drm/card*-*/modes; do grep -q '^3840x2160' "$c" || echo "no-4K: ${c%/modes}"; done   # the two 1080p panels

# Driver / link
timeout 5 modetest -M nvidia-drm 2>&1 | sed -n '/826.*DP-2/,/props/p' | head -50
cat /proc/cmdline | tr ' ' '\n' | grep edid
```

---

## 8. History

- **Before 2026-08-16:** Working at 240 (assumed).
- **2026-08-16:** Sunshine agent added dummy `HDMI-A-4` + `drm.edid_firmware` + `apps.json` prep/undo. No direct 120 cap.
- **2026-09-07 20:02:** `nwg-displays` rewrote `monitors.conf` → `DP-2` forced to `120.0`. After this, any attempt to set 240 via `hyprctl`/`nwg-displays` failed without `bitdepth,10`, so it stayed at 120.
- **2026-09-08 06:52:** Fixed → `DP-2,3840x2160@240.02,1920x0,1,bitdepth,10,vrr,0`, verified `240.01601`.
- **2026-10-22 07:00–08:10:** Connector names had silently shuffled (`DP-2/DP-3/HDMI-A-5` →
  `DP-1/DP-2/HDMI-A-2`): two panels were applying another panel's rules. Root cause: the
  kernel numbers connectors in **driver registration order** (simpledrm + i915 + nvidia-drm),
  which changes between boots on this two-GPU box. Migration applied: `monitors.conf`,
  `workspaces.conf`, `wallpaper.sh`, `wallpaper-guard.sh` and the Sunshine
  `apps.json` prep/undo now resolve panels by **EDID description**; new helper
  `~/.config/hypr/scripts/monitors-stream.sh` (also parser-aware: `keyword` with an `eval`
  fallback). A Lua twin (`monitors.lua`) was removed on 2026-10-23 — nothing loads it, and a
  Lua-mode session generates its own config.
- **2026-10-22 08:18:** `monitors-stream.sh on` (old version) disabled every physical panel
  before `SUNSHINE` existed → Hyprland 0.56.2 SEGV in `CInputManager::refocusLastWindow`;
  uwsm restarted it in `--safe-mode` (default config, no keybinds) — see §4b. Script fixed
  to enable `SUNSHINE` first and never disable the last enabled output.
- **2026-10-23 02:19 — first boot with the EDID rules, verified end-to-end:** normal session
  (no safe-mode), 146 keybinds, **zero config-parse errors** (`Hyprland --verify-config` →
  `config ok`), the 4K negotiated `3840x2160@240.01601` with **10-bit** (`XBGR2101010`) purely
  from `monitors.conf`, the two 1080p panels at 60 / 75 Hz in positions `0x2160` /
  `5760x2160`, workspaces 1 / 3 / 4 on the intended panels, `SUNSHINE` created and disabled,
  and a single mpvpaper instance holding all three panels. Connector names that boot were
  `DP-1` / `HDMI-A-2` / `DP-2` — a **different set from the old era, with no effect on any
  rule**.
- **2026-10-23 11:25 — streaming prep/undo verification (deliberately without panel blanking):**
  ran the `off` path live against the real compositor (SUNSHINE enabled, then disabled, purely as
  a headless off-screen output; the three physical panels were never disabled, so no window could
  move) — exit 0, and every panel mode, position, workspace and wallpaper came back identical.
  The same pass found and fixed a **real defect**: `off` left `SUNSHINE` *enabled*, so every
  stream would have kept a phantom 4th output — exactly what `monitor=SUNSHINE,disable` exists to
  prevent. `off` now ends with `SUNSHINE,disable`, guarded by `enabled_outputs >= 2` so that step
  can never be the one which leaves 0 outputs. A stateful fake-compositor simulation of the whole
  `on` + `off` cycle (applies every `hyprctl` write, counts enabled outputs, aborts at 0) passed
  in all three cases — legacy `.conf` with SUNSHINE present, legacy `.conf` with SUNSHINE absent
  (the 08:18 crash case) and Lua / `--safe-mode` — minimum **1** enabled output, final **3**.
  The full `on` cycle (which blanks all three panels for a few seconds) has still not been run
  live: that remains a deliberate, user-approved-only step.
- **2026-10-23 11:50 — name-literal sweep and nwg-displays neutralised:** swept every live config
  (`~/.config`, `~/.local/bin`, `/etc`) for connector-name literals. Everything boot-reachable is
  either EDID-based or a comment; `~/.local/bin` is clean; the remaining hits are editor history,
  backups, `dots-archive/` and AGS unit-test mocks (none executed). The one real trap was
  `~/.config/nwg-displays/profiles/{Main,sleep}.json` — name-keyed snapshots of the **old era**
  (`HDMI-A-4` / `HDMI-A-5` / `DP-3` / `DP-2`) with `active_profile.json` marking one active. Applying
  a profile would have rewritten `monitors.conf` with those stale names — the same mechanism as the
  2026-09-07 rewrite (which capped the 4K at 120 Hz) and the 2026-10-20 one. Both profiles were
  moved to `*.bak-old-names-20261023`, so nwg-displays has nothing stale left to restore.
  Follow-up the same hour, reading the tool's source: `use-desc` is what decides between writing
  `monitor=<name>` and `monitor=desc:<description>` rules, and that config had it **false** — i.e.
  pressing Apply would have written name-based rules (the same mechanism as 2026-09-07 / 2026-10-20).
  It is now `true`, so the GUI is a safe way to manage these panels if a profile is ever needed
  again; note the two moved-aside profiles also encode the **old top-aligned positions**, so save a
  fresh profile from the current layout rather than restoring them.

---

## 9. Companion Fix Script

> **Note (2026-10-23): the script this section describes was removed** — it was an obsolete
> band-aid, and the reason it existed (a name-based 240 Hz cap) is fixed in `monitors.conf`.
> The modern equivalent is one command, EDID-based and workspace-aware:
> `~/.config/hypr/scripts/monitors-stream.sh off`. The text below is kept as history.

It referenced `~/.local/bin/fix-4k240.sh`. One-shot:
```bash
~/.local/bin/fix-4k240.sh       # apply + verify
~/.local/bin/fix-4k240.sh --check   # only check
~/.local/bin/fix-4k240.sh --isolate # disable secondaries, test, restore
```
