#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)
images_dir="$repo_root/output/qemu/images"
kernel="$images_dir/Image"
initrd="$images_dir/rootfs.cpio.gz"

ros_volume=""
for candidate in "$images_dir/ros2.ext4" "$repo_root/output/images/ros2.ext4"; do
  if [ -f "$candidate" ]; then
    ros_volume="$candidate"
    break
  fi
done

if [ ! -f "$kernel" ] || [ ! -f "$initrd" ]; then
  echo "Kernel or initrd missing. Run ./rebuild_rootfs.sh first." >&2
  exit 1
fi

if [ -n "$ros_volume" ]; then
  exec qemu-system-aarch64 \
    -M virt -cpu cortex-a53 -m 512 \
    -kernel "$kernel" \
    -initrd "$initrd" \
    -append "root=/dev/ram0 console=ttyAMA0 init=/init" \
    -serial mon:stdio \
    -device virtio-gpu-pci \
    -drive "file=$ros_volume,if=virtio,format=raw,readonly=on" \
    -display gtk
fi

echo "[!] ros2.ext4 not present; booting without ROS 2 volume. Run ./rebuild_ros2_volume.sh to generate it." >&2
exec qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 512 \
  -kernel "$kernel" \
  -initrd "$initrd" \
  -append "root=/dev/ram0 console=ttyAMA0 init=/init" \
  -serial mon:stdio \
  -device virtio-gpu-pci \
  -display gtk
