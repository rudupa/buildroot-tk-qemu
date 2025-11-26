#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)
ros_build="$repo_root/output/ros2"
images_dir="$repo_root/output/images"
ros_image="$images_dir/ros2.ext4"

defconfig=myfastboot_ros2_defconfig

mkdir -p "$ros_build"

echo "[*] Configuring ROS 2 filesystem (Buildroot)..."
PATH=/usr/bin:/bin make O="$ros_build" -C "$repo_root" "$defconfig"

echo "[*] Building ROS 2 filesystem image..."
PATH=/usr/bin:/bin make O="$ros_build" -C "$repo_root"

src_ext2="$ros_build/images/rootfs.ext2"
if [ ! -f "$src_ext2" ]; then
    echo "[!] Expected image $src_ext2 missing" >&2
    exit 1
fi

mkdir -p "$images_dir"
cp "$src_ext2" "$ros_image"

# Prefer ext4 variant when Buildroot emits a symlink
if [ -f "$ros_build/images/rootfs.ext4" ]; then
    cp "$ros_build/images/rootfs.ext4" "$ros_image"
fi

sync

for target in "$repo_root/output/qemu/images" "$repo_root/output/pi4/images"; do
    if [ -d "$target" ]; then
        cp "$ros_image" "$target/ros2.ext4"
    fi
done

echo "[*] ROS 2 volume ready at $ros_image"
