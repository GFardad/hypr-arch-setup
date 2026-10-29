#!/usr/bin/env bash
# Graceful close active window — sends Wayland close event rather than killing PID.
# Important for Zen Browser and other multi-window apps where all windows share a main engine.

active_window=$(hyprctl activewindow -j 2>/dev/null || echo '{"address":""}')
# Extract address from JSON output (handles optional spaces after colon)
address=$(echo "$active_window" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('address',''))" 2>/dev/null || echo "")

if [[ -n "$address" ]]; then
    # Send graceful close event to the window by address (not SIGTERM to PID)
    # Matches QML dispatcher syntax: closewindow address:${address}
    hyprctl dispatch closewindow "address:$address" 2>/dev/null || hyprctl dispatch killactive 2>/dev/null || true
else
    # Fallback: try dispatcher killactive (graceful event, not PID kill)
    hyprctl dispatch killactive 2>/dev/null || true
fi
