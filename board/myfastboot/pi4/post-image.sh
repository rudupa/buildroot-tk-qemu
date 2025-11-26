#!/bin/bash

set -e

BOARD_DIR="$(cd "$(dirname "$0")" && pwd)"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
GENIMAGE_CFG="${BINARIES_DIR}/genimage.cfg"
ROS_IMAGE="${BINARIES_DIR}/ros2.ext4"

if [ -f "${ROS_IMAGE}" ]; then
	TEMPLATE="${BOARD_DIR}/genimage-ros.cfg.in"
else
	echo "[!] ros2.ext4 not found; generating sdcard without ROS 2 partition." >&2
	TEMPLATE="${BOARD_DIR}/genimage.cfg.in"
fi

FILES=()
for i in "${BINARIES_DIR}"/*.dtb "${BINARIES_DIR}"/rpi-firmware/*; do
	FILES+=( "${i#${BINARIES_DIR}/}" )
done

KERNEL=$(sed -n 's/^kernel=//p' "${BINARIES_DIR}/rpi-firmware/config.txt")
FILES+=( "${KERNEL}" )

BOOT_FILES=$(printf '\t\t\t"%s",\n' "${FILES[@]}")
export BOOT_FILES

python3 - "$TEMPLATE" "$GENIMAGE_CFG" <<'PY'
import os
import sys
from pathlib import Path

template_path, output_path = sys.argv[1:3]
template = Path(template_path).read_text()
boot_files = os.environ.get("BOOT_FILES", "")
Path(output_path).write_text(template.replace("#BOOT_FILES#", boot_files))
PY

trap 'rm -rf "${ROOTPATH_TMP}"' EXIT
ROOTPATH_TMP="$(mktemp -d)"

rm -rf "${GENIMAGE_TMP}"

genimage \
	--rootpath "${ROOTPATH_TMP}"   \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"

exit $?
