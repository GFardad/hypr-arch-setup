local var_scriptsDir = "$HOME/.config/hypr/scripts"

-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #

-- Commands and Apps to be executed at launch (vendor defaults)

-- ## wallpaper stuff ###
hl.on("hyprland.start", function()
    hl.exec_cmd("swww-daemon --format xrgb")
end)

-- exec-once = mpvpaper '*' -o "load-scripts=no no-audio --loop" $livewallpaper

-- wallpaper random

-- exec-once = $SwwwRandom $wallDIR # random wallpaper switcher every 30 minutes

-- ## Startup ###
hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("$HOME/.config/hypr/scripts/Dropterminal.sh kitty &")
    hl.exec_cmd(var_scriptsDir .. "/Polkit.sh")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("nm-tray")
    hl.exec_cmd("swaync")
end)

-- exec-once = ags

-- exec-once = blueman-applet

-- exec-once = rog-control-center
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("qs -c overview")
    hl.exec_cmd("hypridle")
    hl.exec_cmd(var_scriptsDir .. "/Hyprsunset.sh init")
end)

-- Clipboard manager
hl.on("hyprland.start", function()
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- Rainbow borders (disabled by default; use quick settings menu)

-- exec-once = $UserScripts/RainbowBorders.sh

-- Here are list of features available but disabled by default

-- Persistent wallpaper

-- exec-once = swww-daemon --format xrgb && swww img $wallDIR/mecha-nostalgia.png

-- Gnome polkit for NixOS

-- exec-once = $scriptsDir/Polkit-NixOS.sh

-- xdg-desktop-portal-hyprland (should be auto starting. However, you can force to start)

-- exec-once = $scriptsDir/PortalHyprland.sh
hl.on("hyprland.start", function()
    hl.exec_cmd("~/.config/hypr/scripts/wallpaper.sh")
end)
