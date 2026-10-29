-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Decorations
-- See https://wiki.hyprland.org/Configuring/Variables/#decoration

local wallust_path = os.getenv("HOME") .. "/.config/wallust/colors-waybar.css"
local f = io.open(wallust_path, "r")
local wallust_css = f and f:read("*a") or nil
if f then
    f:close()
end

local decoration = {
    rounding = 8,
    active_opacity = 1.0,
    inactive_opacity = 0.85,
    fullscreen_opacity = 1.0,
    blur = {
        enabled = true,
        size = 8,
        passes = 3,
        new_optimizations = true,
        ignore_opacity = true,
        xray = true,
        noise = 0.05,
    },
    shadow = {
        enabled = true,
        range = 4,
        render_power = 3,
        color = "rgba(00000066)",
    },
}

if wallust_css then
    for hex, name in wallust_css:gmatch("#([0-9a-fA-F]+)%s*[^%s]*%s*([^%s]+)%s*[;}]") do
        -- map a few wallust tokens if present; no-op if names do not match
    end
end

hl.config({ decoration = decoration })
