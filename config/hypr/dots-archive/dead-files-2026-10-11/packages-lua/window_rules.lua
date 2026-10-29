-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Window rules and layer rules
-- See https://wiki.hyprland.org/Configuring/Basics/Window-Rules/

hl.window_rule({
    name = "float-apps",
    match = { class = "^(flameshot|pavucontrol|rofi|wlogout|Pavucontrol)$" },
    float = true,
})

hl.window_rule({
    name = "float-kitty",
    match = { class = "^kitty --class=.*$" },
    float = true,
})

hl.window_rule({
    name = "steam-float",
    match = { class = "^(steam_app_.+|Steam)$" },
    float = true,
})

hl.window_rule({
    name = "steam-focus",
    match = { class = "^(steam_app_.+|Steam)$" },
    stay_focused = true,
})

hl.layer_rule({
    name = "keep-uis-float",
    match = { namespace = "^.*$" },
    no_anim = true,
})
