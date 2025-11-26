#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)
qemu_output="$repo_root/output/qemu"

mkdir -p "$qemu_output"

echo "[*] Configuring Buildroot (QEMU fast boot)..."
PATH=/usr/bin:/bin make O="$qemu_output" -C "$repo_root" my_defconfig

echo "[*] Building QEMU artifacts..."
PATH=/usr/bin:/bin make O="$qemu_output" -C "$repo_root"

kernel="$qemu_output/images/Image"
initrd="$qemu_output/images/rootfs.cpio.gz"

if [ ! -f "$kernel" ] || [ ! -f "$initrd" ]; then
	echo "[!] Missing QEMU kernel or initrd in $qemu_output/images. Build failed?" >&2
	exit 1
fi

echo "[*] Launching QEMU..."
exec "$repo_root/run_qemu.sh" "$@"
