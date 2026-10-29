-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- User Defaults
local M = {}

M.vars = {
    edit = os.getenv("EDITOR") or "nano",
    term = "kitty",
    files = "thunar",
    browser = "firefox",
    rofi = "rofi -show drun",
    lock = "$HOME/.config/hypr/scripts/LockScreen.sh",
    screenshot = "$HOME/.config/hypr/scripts/ScreenShot.sh",
    menu = "rofi -show drun",
    power = "$HOME/.config/hypr/scripts/Wlogout.sh",
    music = "$HOME/.scripts/RofiBeats.sh",
}

return M
