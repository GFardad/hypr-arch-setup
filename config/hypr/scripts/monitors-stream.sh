#!/usr/bin/env bash
# Physical-panel on/off for Sunshine streaming, resolved by EDID DESCRIPTION.
#
#   monitors-stream.sh on     # stream prep: SUNSHINE up first, THEN panels off
#   monitors-stream.sh off    # undo:       panels restored, SUNSHINE disabled again
#   monitors-stream.sh list   # show which connector each panel resolves to now
#
# Why this exists: connector names (DP-1/DP-2/HDMI-A-2 vs DP-2/DP-3/HDMI-A-5)
# depend on which GPU's driver registers its DRM connectors first at boot, so a
# name-based `hyprctl keyword monitor <name>,disable` silently hits the WRONG
# panel on a bad boot. EDID descriptions never change.
#
# CRASH SAFETY (2026-10-22): the old version disabled every physical panel
# BEFORE the headless SUNSHINE output existed, so the compositor briefly had
# zero enabled outputs; Hyprland 0.56.2 segfaulted in
# CInputManager::refocusLastWindow (crash report
# ~/.cache/hyprland/hyprlandCrashReport2765.txt) and uwsm auto-restarted it in
# --safe-mode, which ignores hyprland.conf entirely (session came up with no
# keybinds, default layout). Hence:
#   1. SUNSHINE is brought up FIRST (parked to the right),
#   2. panels are disabled one at a time, never dropping below 1 enabled output, and
#   3. `off` re-disables SUNSHINE only once a physical panel is enabled again.
#
# Parser-mode note: a normal session (legacy .conf) accepts `hyprctl keyword`;
# a Lua-mode session (what --safe-mode starts) rejects it with "keyword can't
# work with non-legacy parsers. Use eval." Every rule below therefore tries
# `keyword` first and falls back to the Lua `eval` form, so this script works in
# both kinds of session.
#
# Called from ~/.config/sunshine/apps.json prep-cmd ("Virtual Desktop (SUNSHINE)").

set -u

DESC_MAIN="PG32UCDM"   # ASUS 4K240 — main
DESC_A="GDM-225JN"     # ChangHong 1080p60 over HDMI (left)
DESC_B="GDM-275LN"     # ChangHong 1080p75 over DP   (right)

resolve() { # resolve <description-substring> -> current connector name
    hyprctl -j monitors all 2>/dev/null |
        jq -r --arg d "$1" '.[] | select(.description | contains($d)) | .name' 2>/dev/null |
        head -1
}

set_monitor() { # set_monitor <target> <mode> <position> [extra-options]
    local target="$1" mode="$2" pos="$3" extra="${4:-}" lua_extra=""
    case "${extra}" in *bitdepth*10*) lua_extra=", bitdepth=10" ;; esac
    hyprctl keyword monitor "${target},${mode},${pos},1${extra:+,${extra}},vrr,0" >/dev/null 2>&1 && return 0
    hyprctl eval "hl.monitor({output='${target}', mode='${mode}', position='${pos}', scale=1${lua_extra}, vrr=0})" >/dev/null 2>&1
}

disable_monitor() { # disable_monitor <target>
    hyprctl keyword monitor "${1},disable" >/dev/null 2>&1 && return 0
    hyprctl eval "hl.monitor({output='${1}', disabled=true})" >/dev/null 2>&1
}

apply_panel() { # apply_panel <desc> <mode> <position> [extra-options]
    local n
    n=$(resolve "$1")
    [ -n "$n" ] || return 0
    set_monitor "$n" "$2" "$3" "${4:-}"
}

disable_panel() { # disable_panel <desc>
    local n
    n=$(resolve "$1")
    [ -n "$n" ] || return 0
    disable_monitor "$n"
}

enabled_outputs() { # how many outputs are currently enabled
    hyprctl -j monitors all 2>/dev/null | jq '[.[] | select(.disabled == false)] | length' 2>/dev/null
}

ensure_sunshine() { # make sure the headless SUNSHINE output exists
    hyprctl -j monitors all 2>/dev/null | jq -e '.[] | select(.name == "SUNSHINE")' >/dev/null 2>&1 && return 0
    hyprctl output create headless SUNSHINE >/dev/null 2>&1
    sleep 0.4
}

rehome_workspaces() { # give the ruled workspaces back to their physical panels
    local main a b ws
    main=$(resolve "$DESC_MAIN"); a=$(resolve "$DESC_A"); b=$(resolve "$DESC_B")
    if [ -n "$main" ]; then
        hyprctl dispatch moveworkspacetomonitor 1 "$main" >/dev/null 2>&1
        hyprctl dispatch moveworkspacetomonitor 2 "$main" >/dev/null 2>&1
    fi
    [ -n "$b" ] && hyprctl dispatch moveworkspacetomonitor 3 "$b" >/dev/null 2>&1
    [ -n "$a" ] && hyprctl dispatch moveworkspacetomonitor 4 "$a" >/dev/null 2>&1
    # anything still parked on SUNSHINE comes home to the main panel
    [ -n "$main" ] || return 0
    for ws in $(hyprctl -j workspaces 2>/dev/null |
                jq -r '.[] | select(.monitor == "SUNSHINE") | .id' 2>/dev/null); do
        hyprctl dispatch moveworkspacetomonitor "$ws" "$main" >/dev/null 2>&1
    done
}

case "${1:-}" in
    on)
        ensure_sunshine
        # 1) bring SUNSHINE up first, parked to the right of the panels
        set_monitor "SUNSHINE" "1920x1080@60.0" "7680x2160"
        sleep 0.6
        # 2) panels off one at a time; never leave the compositor with 0 outputs
        for d in "$DESC_MAIN" "$DESC_A" "$DESC_B"; do
            [ "$(enabled_outputs)" -le 1 ] && break
            disable_panel "$d"
            sleep 0.4
        done
        # 3) panels released their CRTCs — move SUNSHINE to the origin
        set_monitor "SUNSHINE" "1920x1080@60.0" "0x0"
        ;;
    off)
        set_monitor "SUNSHINE" "1920x1080@60.0" "7680x2160"
        apply_panel "$DESC_MAIN" "3840x2160@240.02" "1920x1080" "bitdepth,10"
        apply_panel "$DESC_A" "1920x1080@60.0" "0x2160"
        apply_panel "$DESC_B" "1920x1080@75.0" "5760x2160"
        sleep 0.5
        rehome_workspaces
        # 4) return SUNSHINE to its idle state, matching monitor=SUNSHINE,disable in
        #    monitors.conf — otherwise a phantom 4th output survives every stream and
        #    the wallpaper stack paints an encoder-heavy wallpaper onto it.
        #    Guard: only when a physical panel is actually up (>=2 enabled outputs),
        #    so this step can never be the one that leaves the session with 0 outputs.
        [ "$(enabled_outputs)" -ge 2 ] && disable_monitor "SUNSHINE"
        ;;
    list)
        for d in "$DESC_MAIN" "$DESC_A" "$DESC_B"; do
            printf '%s\t%s\n' "$d" "$(resolve "$d")"
        done
        printf 'SUNSHINE\t%s\n' \
            "$(hyprctl -j monitors all 2>/dev/null | jq -r '.[] | select(.name == "SUNSHINE") | .name' | head -1)"
        ;;
    *)
        echo "usage: $(basename "$0") {on|off|list}" >&2
        exit 2
        ;;
esac
