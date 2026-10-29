-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Keybinds
-- See https://wiki.hyprland.org/Configuring/Keywords/

local super = "SUPER"
local ctrl = "CTRL"
local alt = "ALT"
local shift = "SHIFT"

hl.bind(super .. " + D", hl.dsp.exec_cmd("ags toggle launcher -i ags2-shell"))
hl.bind(super .. " + B", hl.dsp.exec_cmd("xdg-open https://"))
hl.bind(super .. " + Return", hl.dsp.exec_cmd("kitty"))
hl.bind(super .. " + E", hl.dsp.exec_cmd("thunar"))

hl.bind(ctrl .. " + " .. alt .. " + L", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/LockScreen.sh"))
hl.bind(ctrl .. " + " .. alt .. " + P", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Wlogout.sh"))

hl.bind(super .. " + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --now"))
hl.bind(super .. " + SHIFT + Print", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ScreenShot.sh --area"))

hl.bind(super .. " + Q", hl.dsp.window.kill())
hl.bind(super .. " + Space", hl.dsp.window.float({ action = "toggle" }))

hl.bind(super .. " + left",   hl.dsp.focus({ direction = "left" }))
hl.bind(super .. " + right",  hl.dsp.focus({ direction = "right" }))
hl.bind(super .. " + up",     hl.dsp.focus({ direction = "up" }))
hl.bind(super .. " + down",   hl.dsp.focus({ direction = "down" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(super .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(super .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(super .. " + SHIFT + Return", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/Dropterminal.sh kitty"))
hl.bind(super .. " + " .. alt .. " + L", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ChangeLayout.sh"))
hl.bind(super .. " + " .. alt .. " + O", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/ChangeBlur.sh"))
