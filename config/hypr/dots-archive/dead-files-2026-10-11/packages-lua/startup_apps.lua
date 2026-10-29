-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Startup applications
-- See https://wiki.hyprland.org/Configuring/Basics/Autostart/

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    # BROKEN STORAGE REFERENCE REMOVED: hl.exec_cmd("$HOME/.local/share/pipx/venvs/hypr-session/bin/hypr-session restore --wait")
    hl.exec_cmd("waybar")
    hl.exec_cmd("ags")
    hl.exec_cmd("dunst")
end)
