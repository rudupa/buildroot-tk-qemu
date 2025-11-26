#!/bin/bash
set -euo pipefail

if ! command -v /usr/bin/time >/dev/null 2>&1; then
    echo "[WARN] /usr/bin/time not found; falling back to shell built-in." >&2
    time_cmd=time
else
    time_cmd="/usr/bin/time -f [HOST]\\ QEMU\\ finished\\ after\\ %E"
fi

if [ ! -x ./run_qemu.sh ]; then
    echo "[ERROR] run_qemu.sh is missing or not executable." >&2
    exit 1
fi

# Measure wall-clock duration on the host for a QEMU session.
# Stop QEMU once the guest prints the Tk ready marker to capture boot latency.
if [ "$time_cmd" = time ]; then
    $time_cmd ./run_qemu.sh
else
    eval "$time_cmd ./run_qemu.sh"
fi
