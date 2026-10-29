#!/usr/bin/env bash
# Re-apply the video wallpaper whenever the monitor layout changes.
#
# Why this exists: wallpaper.sh only paints ENABLED outputs at the moment it
# runs. Anything that changes the monitor set afterwards (Sunshine enable/
# disable, hotplug, the headless SUNSHINE output being recreated, a monitor
# coming back from a long DPMS sleep) leaves the wallpapers stale or missing
# until something happens to re-run the script. That is the "wallpaper just
# stopped" failure mode. This listener closes it.
#
# It watches Hyprland's socket2 event stream and re-runs wallpaper.sh after the
# layout settles.

set -u

sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [ -z "$sig" ]; then
    echo "wallpaper-watch: HYPRLAND_INSTANCE_SIGNATURE is unset" >&2
    exit 1
fi

runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
sock="$runtime/hypr/$sig/.socket2.sock"
wp="$HOME/.config/hypr/scripts/wallpaper.sh"
lock="$runtime/wallpaper-watch.lock"

if [ ! -S "$sock" ]; then
    echo "wallpaper-watch: no socket at $sock — giving up" >&2
    exit 1
fi

echo "wallpaper-watch: listening on $sock" >&2

# Read the event stream. socat -U reads the socket and writes to stdout.
socat -U - "UNIX-CONNECT:$sock" | while IFS= read -r line; do
    case "$line" in
        monitoradded*|monitorremoved*|monitoraddedv2*|monitorremovedv2*) ;;
        *) continue ;;
    esac

    # Debounce. A single layout change emits several events back to back, and
    # at boot every monitor emits one. The first event in a burst takes the
    # lock and sleeps long enough for the rest of the burst to land, so the
    # re-run it performs already sees the final layout. Events that arrive
    # while the lock is held are dropped, which is exactly what we want: they
    # are the same change.
    if ! mkdir "$lock" 2>/dev/null; then
        # Stale lock from a killed run: reclaim it if it is older than 60s.
        if [ -n "$(find "$lock" -maxdepth 0 -mmin +1 2>/dev/null)" ]; then
            echo "wallpaper-watch: reclaiming stale lock" >&2
            rmdir "$lock" 2>/dev/null || true
        fi
        continue
    fi

    cleanup() { rmdir "$lock" 2>/dev/null || true; }
    trap cleanup EXIT INT TERM

    echo "wallpaper-watch: layout changed, settling" >&2
    sleep 2
    "$wp" || echo "wallpaper-watch: wallpaper.sh exited $?" >&2

    cleanup
    trap - EXIT INT TERM
done
