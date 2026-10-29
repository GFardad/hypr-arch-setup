#!/usr/bin/env bash
# Graceful close active window — sends Wayland close event rather than killing PID.
# Important for Zen Browser and other multi-window apps where all windows share a main engine.

active_window=$(hyprctl activewindow -j 2>/dev/null || echo '{"address":""}')
# Get the window address
address=$(echo "$active_window" | grep -o '"address":"[^"]*"' | head -n1 | cut -d'"' -f4)

if [[ -n "$address" ]]; then
    # Send graceful close event to the window (not SIGTERM to PID)
    hyprctl dispatch closewindow "address:$address" 2>/dev/null || true
else
    # Fallback: try dispatcher killactive (graceful event, not PID kill)
    hyprctl dispatch killactive 2>/dev/null || true
fi
