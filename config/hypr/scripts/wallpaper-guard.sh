#!/usr/bin/env bash
# Self-heal guard for the video wallpaper.
#
# Restarts wallpaper.sh if mpvpaper has died while an eligible output is enabled.
# Without this a crash (GPU hiccup, driver reset, OOM) leaves no wallpaper until
# something happens to fire a monitor event - the "it just stopped" symptom.
#
# During Sunshine streaming the physical outputs are disabled, so no eligible
# output matches and the guard correctly stays hands-off.
#
# Optional: RSS_MAX_KB (default 0 = off) also restarts once the wallpaper's host
# RAM exceeds that figure. mpv shows a slow ~1.4 MB/min drift on long uptimes;
# left off by default because host RAM is abundant here.
#
# Context: ~/.config/hypr/wallpaper-ARCHITECTURE.md

set -u

wp="$HOME/.config/hypr/scripts/wallpaper.sh"
INTERVAL="${GUARD_INTERVAL:-45}"
RSS_MAX_KB="${RSS_MAX_KB:-0}"

while true; do
    sleep "$INTERVAL"

    P=$(ps -eo pid=,stat=,comm= | awk '$3=="mpvpaper" && $2 !~ /Z/ {print $1}' | head -1)

    if [ -n "$P" ]; then
        if [ "$RSS_MAX_KB" -gt 0 ]; then
            RSS=$(awk '/VmRSS/{print $2}' "/proc/$P/status" 2>/dev/null || echo 0)
            if [ -n "$RSS" ] && [ "$RSS" -gt "$RSS_MAX_KB" ]; then
                echo "wallpaper-guard: RSS ${RSS}kB > ${RSS_MAX_KB}kB, restarting to drain the leak" >&2
                "$wp"
            fi
        fi
    else
        # Eligibility by EDID description, not by connector name: names shuffle
        # between boots on this two-GPU box (see ~/.config/hypr/monitors.conf).
        if hyprctl -j monitors all 2>/dev/null \
            | jq -r '.[] | select(.disabled == false) | .description' 2>/dev/null \
            | grep -qE 'PG32UCDM|GDM-275LN|GDM-225JN'; then
            echo "wallpaper-guard: no wallpaper running but outputs present - restarting" >&2
            "$wp"
        fi
    fi
done
