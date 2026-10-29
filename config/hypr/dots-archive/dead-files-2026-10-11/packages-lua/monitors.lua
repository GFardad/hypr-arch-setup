-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Monitors
-- See https://wiki.hyprland.org/Configuration/Monitors/

hl.monitor({
    output = "HDMI-A-4",
    mode = "1920x1080@60.0",
    position = "7680x1080",
    scale = 1,
})

hl.monitor({
    output = "DP-2",
    mode = "3840x2160@240.02",
    position = "1920x0",
    scale = 1,
    bitdepth = 10,
    vrr = 0
})

hl.monitor({
    output = "HDMI-A-5",
    mode = "1920x1080@60.0",
    position = "0x1080",
    scale = 1,
    cm = "srgb",
    sdr_eotf = "srgb",
    sdrbrightness = 1.05,
    sdrsaturation = 1.35,
    sdr_min_luminance = 0.18,
    sdr_max_luminance = 100,
})

hl.monitor({
    output = "DP-3",
    mode = "1920x1080@75.0",
    position = "5760x1080",
    scale = 1,
    cm = "srgb",
    sdr_eotf = "srgb",
    sdrbrightness = 1.05,
    sdrsaturation = 1.35,
    sdr_min_luminance = 0.18,
    sdr_max_luminance = 100,
})
