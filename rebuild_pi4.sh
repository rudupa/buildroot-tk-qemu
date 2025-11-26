#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)
pi_output="$repo_root/output/pi4"
pi_images="$pi_output/images"
ros_source="$repo_root/output/images/ros2.ext4"

mkdir -p "$pi_output"

echo "[*] Configuring Buildroot for Raspberry Pi 4..."
PATH=/usr/bin:/bin make O="$pi_output" -C "$repo_root" myfastboot_rpi4_defconfig

if [ -f "$ros_source" ]; then
	mkdir -p "$pi_images"
	cp "$ros_source" "$pi_images/ros2.ext4"
else
	echo "[!] ros2.ext4 not found. Run ./rebuild_ros2_volume.sh to populate the secondary partition." >&2
fi

echo "[*] Building Raspberry Pi 4 image..."
PATH=/usr/bin:/bin make O="$pi_output" -C "$repo_root"

if [ -f "$pi_images/sdcard.img" ]; then
	echo "[*] Done. Flash $pi_images/sdcard.img to an SD card for boot testing."
else
	echo "[*] Build completed.";
fi
