#!/bin/bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")" && pwd)

echo "[*] Rebuilding rootfs..."
PATH=/usr/bin:/bin make -C "$repo_root"

echo "[*] Launching QEMU..."
exec "$repo_root/run_qemu.sh"
