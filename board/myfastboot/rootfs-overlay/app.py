#!/usr/bin/env python3
"""Minimal framebuffer clock UI for fast boot testing."""

import mmap
import os
import signal
import struct
import sys
import time
from typing import Tuple

FB_PATH = "/dev/fb0"
SYSFS_FB = "/sys/class/graphics/fb0"
WAIT_INTERVAL = 0.05
WAIT_TIMEOUT = 5.0

GLYPHS = {
    "0": ("111", "101", "101", "101", "111"),
    "1": ("010", "110", "010", "010", "111"),
    "2": ("111", "001", "111", "100", "111"),
    "3": ("111", "001", "111", "001", "111"),
    "4": ("101", "101", "111", "001", "001"),
    "5": ("111", "100", "111", "001", "111"),
    "6": ("111", "100", "111", "101", "111"),
    "7": ("111", "001", "010", "010", "010"),
    "8": ("111", "101", "111", "101", "111"),
    "9": ("111", "101", "111", "001", "111"),
    ":": ("000", "010", "000", "010", "000"),
    " ": ("000", "000", "000", "000", "000"),
}


def wait_for_framebuffer(timeout: float) -> None:
    """Block until /dev/fb0 exists or timeout expires."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        if os.path.exists(FB_PATH):
            return
        time.sleep(WAIT_INTERVAL)
    raise RuntimeError("Framebuffer device /dev/fb0 not found")


def read_fb_geometry() -> Tuple[int, int, int]:
    """Return width, height, and bits-per-pixel from sysfs."""
    with open(os.path.join(SYSFS_FB, "virtual_size"), "r", encoding="ascii") as handle:
        raw = handle.read().strip()
    width_str, height_str = raw.split(",")
    width = int(width_str)
    height = int(height_str)
    with open(os.path.join(SYSFS_FB, "bits_per_pixel"), "r", encoding="ascii") as handle:
        bpp = int(handle.read().strip())
    return width, height, bpp


def pack_color(r: int, g: int, b: int, bpp: int) -> bytes:
    """Pack an RGB color into framebuffer-native byte representation."""
    if bpp == 32:
        value = (r & 0xFF) | ((g & 0xFF) << 8) | ((b & 0xFF) << 16)
        return struct.pack("<I", value)
    if bpp == 16:
        value = ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3)
        return struct.pack("<H", value)
    raise RuntimeError(f"Unsupported framebuffer depth: {bpp} bpp")


def fill_screen(mm: mmap.mmap, color: bytes, pixels: int) -> None:
    """Fill the entire framebuffer with a solid color."""
    mm[:] = color * pixels


def draw_block(
    mm: mmap.mmap,
    stride: int,
    bytes_per_pixel: int,
    x: int,
    y: int,
    width: int,
    height: int,
    color: bytes,
) -> None:
    """Draw a solid rectangle at (x, y) with the given size."""
    row_span = color * width
    offset_base = y * stride + x * bytes_per_pixel
    for row in range(height):
        offset = offset_base + row * stride
        mm[offset : offset + len(row_span)] = row_span


def draw_char(
    mm: mmap.mmap,
    stride: int,
    bytes_per_pixel: int,
    x: int,
    y: int,
    glyph_key: str,
    scale: int,
    color: bytes,
) -> None:
    glyph = GLYPHS.get(glyph_key, GLYPHS[" "])
    for row_index, row_bits in enumerate(glyph):
        for col_index, bit in enumerate(row_bits):
            if bit != "1":
                continue
            draw_block(
                mm=mm,
                stride=stride,
                bytes_per_pixel=bytes_per_pixel,
                x=x + col_index * scale,
                y=y + row_index * scale,
                width=scale,
                height=scale,
                color=color,
            )


def hide_cursor() -> None:
    try:
        sys.stdout.write("\033[?25l")
        sys.stdout.flush()
    except OSError:
        pass


def show_cursor() -> None:
    try:
        sys.stdout.write("\033[?25h")
        sys.stdout.flush()
    except OSError:
        pass


def render_clock(
    mm: mmap.mmap,
    stride: int,
    bytes_per_pixel: int,
    width: int,
    height: int,
    fg: bytes,
    bg: bytes,
) -> None:
    current = time.strftime("%H:%M:%S")
    scale = max(1, min(width // (len(current) * 6), height // 12))
    char_width = 3 * scale
    char_height = 5 * scale
    spacing = scale
    total_width = len(current) * char_width + (len(current) - 1) * spacing
    origin_x = max(0, (width - total_width) // 2)
    origin_y = max(0, (height - char_height) // 2)

    fill_screen(mm, bg, width * height)

    x_cursor = origin_x
    for character in current:
        draw_char(
            mm=mm,
            stride=stride,
            bytes_per_pixel=bytes_per_pixel,
            x=x_cursor,
            y=origin_y,
            glyph_key=character,
            scale=scale,
            color=fg,
        )
        x_cursor += char_width + spacing
    mm.flush()


def main() -> int:
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    signal.signal(signal.SIGINT, lambda *_: sys.exit(0))

    try:
        wait_for_framebuffer(WAIT_TIMEOUT)
    except RuntimeError as err:
        print(f"[BOOT] GUI failed: {err}", file=sys.stderr, flush=True)
        return 1

    width, height, bpp = read_fb_geometry()
    if bpp not in (16, 32):
        print(f"[BOOT] GUI failed: unsupported bpp {bpp}", file=sys.stderr, flush=True)
        return 1

    bytes_per_pixel = bpp // 8
    framebuffer_size = width * height * bytes_per_pixel

    fg = pack_color(38, 194, 129, bpp)
    bg = pack_color(32, 32, 32, bpp)

    hide_cursor()
    ready_announced = False

    try:
        with open(FB_PATH, "r+b", buffering=0) as fb:
            with mmap.mmap(
                fb.fileno(),
                framebuffer_size,
                mmap.MAP_SHARED,
                mmap.PROT_READ | mmap.PROT_WRITE,
            ) as mm:
                stride = width * bytes_per_pixel
                while True:
                    render_clock(
                        mm=mm,
                        stride=stride,
                        bytes_per_pixel=bytes_per_pixel,
                        width=width,
                        height=height,
                        fg=fg,
                        bg=bg,
                    )
                    if not ready_announced:
                        try:
                            with open("/proc/uptime", "r", encoding="ascii") as uptime_file:
                                uptime = float(uptime_file.read().split()[0])
                            print(f"[BOOT] GUI ready at {uptime:6.3f}s", flush=True)
                        except (OSError, ValueError) as exc:
                            print(f"[BOOT] GUI ready (uptime unavailable): {exc}", flush=True)
                        ready_announced = True
                    time.sleep(0.2)
    finally:
        show_cursor()
    return 0


if __name__ == "__main__":
    sys.exit(main())