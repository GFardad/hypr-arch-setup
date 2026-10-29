#!/bin/bash
if pgrep -x "plasmawindowed" > /dev/null; then
    pkill plasmawindowed
else
    # اجرای مخفی و سریع
    plasmawindowed org.kde.plasma.clipboard & 
    
    # استفاده از ابزار جادویی hyprctl برای اعمال فوری قانون شناور بدون درگیر کردن کاربر
    # این دستور قبل از اینکه پنجره فرصت تایل شدن داشته باشد، آن را فلوت می‌کند
    hyprctl keyword windowrule "float, ^(org.kde.plasmawindowed)$"
    hyprctl keyword windowrule "size 450 600, ^(org.kde.plasmawindowed)$"
    hyprctl keyword windowrulev2 "move cursor -50% -50%, class:^(org.kde.plasmawindowed)$"
fi