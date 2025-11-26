#!/bin/bash
qemu-system-aarch64 \
  -M virt -cpu cortex-a53 -m 512 \
  -kernel output/images/Image \
  -initrd output/images/rootfs.cpio.gz \
  -append "root=/dev/ram0 console=ttyAMA0 init=/init" \
  -serial mon:stdio \
  -device virtio-gpu-pci \
  -display gtk
