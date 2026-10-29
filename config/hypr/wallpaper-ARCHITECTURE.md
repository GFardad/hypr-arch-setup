# Video Wallpaper Architecture (Hyprland / mpvpaper)

Status: live and verified. This documents how the animated wallpaper stack is
wired, why each choice was made, and what was measured and ruled out so nobody
re-derives it.

## Goal and constraints

- One animated video wallpaper across the three physical outputs: DP-2 (4K),
  HDMI-A-5 (1080p), DP-3 (1080p).
- The headless `SUNSHINE` output must NEVER get a wallpaper, and must not waste
  VRAM while streaming.
- Hardware: NVIDIA RTX 3060 Ti, 8 GiB VRAM. Budget: stay under ~800 MiB for the
  wallpaper so games have headroom. Host RAM is effectively unlimited; CPU is
  plentiful (16 threads).

## Pipeline

```
output_1080p_hevc_nvenc.mp4  (HEVC Main 8-bit, 1080p30)
        |
   single mpvpaper process  (one decoder, one GL context)
        |  hwdec=nvdec + hwdec-extra-frames=0
   decoded frames (NVDec hardware, VRAM surface pool)
        |
   mpv renders one surface per output
        +--> DP-2     (3840x2160, upscaled from 1080p)
        +--> HDMI-A-5 (1920x1080)
        +--> DP-3     (1920x1080)
```

Three layer surfaces, all owned by ONE mpvpaper PID. mpvpaper accepts a
space-separated output list as a SINGLE argument:

```
mpvpaper -o "$MPV_OPTS" "DP-2 HDMI-A-5 DP-3" /path/to/video
```

Passing the outputs as separate argv entries does NOT work: mpvpaper takes the
next argument as the filename and fails with "Failed to open HDMI-A-5".

## The shared-instance decision (why one process, not three)

Measured on 3 outputs of the 1080p file:

| Approach | VRAM | CPU | Host RAM |
|---|---|---|---|
| 3 separate mpvpaper processes | 855 MiB | 168% | 1591 MB |
| 1 shared process (nvdec, default frames) | 725 MiB | 8.7% | 574 MB |
| 1 shared process (nvdec, extra-frames=0) | 653 MiB | 8-10% | 540 MB |

A single instance shares one decoder and one GL context. Adding another 1080p
monitor costs only ~20 MiB. The tradeoff is blast radius: one process backs all
three surfaces, so if it dies all wallpapers go down at once.

## Why nvdec (hardware decode)

Measured on this file, one shared instance:

| Decode | VRAM | CPU | RAM |
|---|---|---|---|
| software (hwdec=no) | 497 MiB | 60% | 664 MB |
| nvdec | 653 MiB | 8-10% | 540 MB |

nvdec costs ~156 MiB more VRAM but drops CPU ~6x. Given host RAM is free and CPU
is not, nvdec is the correct side of the trade under the ~800 MiB budget.

`hwdec-extra-frames=0` (default is 6) trims the NVDec surface pool: 725 -> 653
MiB with identical output and no errors.

## Why the 4K panel is fed 1080p

DP-2 is 3840x2160. Decoding the native 4K master with nvdec costs ~1857 MiB per
instance and blows the budget on a single monitor. Feeding the 1080p file and
letting mpv upscale is visually indistinguishable on this content (soft fog +
falling snow, no fine detail or text) - confirmed with a 1:1 crop comparison - so
all three outputs share the 1080p source. Roughly 1200 MiB saved.

## SUNSHINE is hard-excluded

In `wallpaper.sh`, the target loop has a hard rule before the map lookup:

```bash
[ "$out" = SUNSHINE ] && continue
```

SUNSHINE is a headless streaming target, not a display. A wallpaper there is
invisible except during a stream and wastes ~650 MiB of VRAM 24/7. Streams get a
black background instead.

## Resource behavior during streaming

Sunshine's prep step (`apps.json`) disables DP-2/HDMI-A-5/DP-3 and reconfigures
SUNSHINE, then runs `wallpaper.sh`. With no physical output enabled, the target
set is empty, so the script STOPS the wallpaper and frees its VRAM:

```
wallpaper.sh: no physical output enabled - stopping wallpaper to free VRAM
```

On stream end the undo step re-enables the monitors (with a settle sleep) and
re-runs `wallpaper.sh`, which restarts the wallpaper. The monitor-event watcher
provides a second, independent restoration path.

## Self-healing

`wallpaper-watch.sh` listens on Hyprland's `socket2` for monitor add/remove
events. After a debounce it re-runs `wallpaper.sh`, so any monitor-layout change
(hotplug, Sunshine enable/disable, SUNSHINE recreated) heals the wallpaper
automatically. It is started from `hyprland.conf` and is debounced with a lock
plus a 2s settle that coalesces bursts of events.

## The two teardown rules (important)

In `wallpaper.sh` the kill sits AFTER the target set is computed:

- targets NON-empty -> kill all, relaunch (idempotent re-run).
- targets EMPTY -> kill all and stop (streaming: free VRAM).

Killing is never done before we know what we will draw, so a partial or failed
run cannot blank the screens and then exit without a replacement.

## Files

| Path | Role |
|---|---|
| `~/.config/hypr/scripts/wallpaper.sh` | Teardown + start. Invoked at boot, by Sunshine prep/undo, and by the watcher. |
| `~/.config/hypr/scripts/wallpaper-watch.sh` | Monitor-event watcher (socket2); re-runs wallpaper.sh after layout changes. |
| `~/.config/hypr/hyprland.conf` | exec-once: SUNSHINE + wallpaper.sh, then wallpaper-watch.sh. |
| `~/.config/sunshine/apps.json` | Stream prep/undo: monitor reconfig + wallpaper.sh. |
| `~/Downloads/Wallpaper/output_1080p_hevc_nvenc.mp4` | The in-use source (1080p HEVC Main 8). |
| `~/Downloads/Wallpaper/output_4k_hevc_nvenc.mp4` | Native 4K master (not decoded - too much VRAM). |

## Tuning knobs measured and ruled out

| Knob | Result |
|---|---|
| `vd-queue-enable` | no change |
| `cuda-copy` | no change |
| `gpu-api=vulkan` | no change |
| `gpu-context=wayland` | no change |
| `vo=gpu-next` | identical |
| software GL (`LIBGL_ALWAYS_SOFTWARE`, forced Mesa EGL) | fails; mpv binds NVIDIA EGL, Mesa cannot open the DRM device |
| `hwdec-extra-frames=0` | works: 725 -> 653 MiB |

The ~349 MiB per-process GL context is irreducible on this driver. It dominates
the footprint; the video itself is a minority of it.

## Operational notes

- Restart manually: `bash ~/.config/hypr/scripts/wallpaper.sh`
- Stop the VRAM logger if it is running: `pkill -f /tmp/wpmem2.sh`
- Backups from the optimization work: `wallpaper.sh.bak.*` and
  `apps.json.bak.*` in their respective directories.
- The per-output fallback path still exists: if the output-to-video map ever
  diverges (different videos per monitor), the script spawns one process per
  output instead of one shared instance.
