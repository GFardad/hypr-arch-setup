#!/bin/bash
# چک کردن خطاهای Btrfs
ERRORS=$(sudo btrfs device stats / | grep -v ' 0' | wc -l)

if [ "$ERRORS" -gt 0 ]; then
    notify-send -u critical "Disk Error Detected!" "Btrfs reported I/O errors on /dev/nvme1n1. Check 'btrfs device stats' immediately."
fi

# چک کردن دمای بحرانی
TEMP=$(sudo smartctl -C -A /dev/nvme1n1 | grep 'Temperature:' | awk '{print $2}')
if [ "$TEMP" -gt 75 ]; then
    notify-send -u critical "High Disk Temperature!" "Your NVMe drive is at $TEMP°C. Take care!"
fi
