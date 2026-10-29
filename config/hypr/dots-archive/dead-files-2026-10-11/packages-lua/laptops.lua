-- /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
-- Laptop-specific config
-- See https://wiki.hyprland.org/Configuring/Laptop/

local function is_laptop()
    local f = io.open("/sys/class/dmi/id/chassis_type", "r")
    if not f then
        return false
    end
    local t = f:read("*l")
    f:close()
    local n = tonumber(t)
    return n and (n == 9 or n == 10 or n == 14 or n == 31)
end

if is_laptop() then
    hl.config({
        general = {
            laptop_inhibit_swipe = false,
        },
    })
end
