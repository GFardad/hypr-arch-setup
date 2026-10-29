-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Animations
-- https://wiki.hyprland.org/Configuring/Animations/

hl.config({
    animations = {
        enabled = true,
        workspace_wraparound = true,
    },
})

hl.curve("smoothOut", { type = "bezier", points = { {0.34, 1.56}, {0.64, 1} } })

hl.animation({ leaf = "windows",      enabled = true, speed = 4,   bezier = "smoothOut", overshoot = true })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 3,   bezier = "smoothOut", overshoot = true })
hl.animation({ leaf = "border",       enabled = true, speed = 4,   bezier = "smoothOut" })
hl.animation({ leaf = "fade",         enabled = true, speed = 4,   bezier = "smoothOut", overshoot = true })
hl.animation({ leaf = "fadeIn",       enabled = true, speed = 4,   bezier = "smoothOut", overshoot = true })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 3,   bezier = "smoothOut", overshoot = true, reverse = true })
