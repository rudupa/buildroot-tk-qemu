#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)

echo "[*] Configuring Buildroot for Raspberry Pi 4..."
PATH=/usr/bin:/bin make -C "$repo_root" myfastboot_rpi4_defconfig

echo "[*] Building Raspberry Pi 4 image..."
PATH=/usr/bin:/bin make -C "$repo_root"

echo "[*] Done. Flash output/images/sdcard.img to an SD card for boot testing."
