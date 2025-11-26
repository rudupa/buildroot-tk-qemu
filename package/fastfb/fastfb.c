// Minimal framebuffer clock to replace the Python prototype.

#include <errno.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>

#define FB_PATH "/dev/fb0"
#define WAIT_TIMEOUT_SECONDS 5.0
#define WAIT_INTERVAL_NS 50000000L
#define GLYPH_W 3
#define GLYPH_H 5

static volatile sig_atomic_t g_stop;

static void handle_signal(int sig)
{
	(void)sig;
	g_stop = 1;
}

struct glyph {
	char ch;
	uint8_t rows[GLYPH_H];
};

static const struct glyph kGlyphs[] = {
	{ '0', { 0x7, 0x5, 0x5, 0x5, 0x7 } },
	{ '1', { 0x2, 0x6, 0x2, 0x2, 0x7 } },
	{ '2', { 0x7, 0x1, 0x7, 0x4, 0x7 } },
	{ '3', { 0x7, 0x1, 0x7, 0x1, 0x7 } },
	{ '4', { 0x5, 0x5, 0x7, 0x1, 0x1 } },
	{ '5', { 0x7, 0x4, 0x7, 0x1, 0x7 } },
	{ '6', { 0x7, 0x4, 0x7, 0x5, 0x7 } },
	{ '7', { 0x7, 0x1, 0x2, 0x2, 0x2 } },
	{ '8', { 0x7, 0x5, 0x7, 0x5, 0x7 } },
	{ '9', { 0x7, 0x5, 0x7, 0x1, 0x7 } },
	{ ':', { 0x0, 0x2, 0x0, 0x2, 0x0 } },
	{ ' ', { 0x0, 0x0, 0x0, 0x0, 0x0 } },
};

static const uint8_t *lookup_glyph(char ch)
{
	size_t count = sizeof(kGlyphs) / sizeof(kGlyphs[0]);
	for (size_t i = 0; i < count; ++i) {
		if (kGlyphs[i].ch == ch) {
			return kGlyphs[i].rows;
		}
	}
	return kGlyphs[count - 1].rows; /* space fallback */
}

static int wait_for_framebuffer(const char *path, double timeout)
{
	struct timespec interval = { 0, WAIT_INTERVAL_NS };
	struct timespec start, now;

	if (clock_gettime(CLOCK_MONOTONIC, &start) != 0) {
		return -1;
	}

	while (1) {
		if (access(path, F_OK) == 0) {
			return 0;
		}

		nanosleep(&interval, NULL);

		if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
			return -1;
		}

		double elapsed = (double)(now.tv_sec - start.tv_sec) +
			(double)(now.tv_nsec - start.tv_nsec) / 1e9;
		if (elapsed >= timeout) {
			return -1;
		}
	}
}

static uint32_t pack_color(int bpp, uint8_t r, uint8_t g, uint8_t b)
{
	if (bpp == 32) {
		return (uint32_t)r | ((uint32_t)g << 8) | ((uint32_t)b << 16);
	}
	if (bpp == 16) {
		return (uint32_t)(((r & 0xF8) << 8) | ((g & 0xFC) << 3) | ((b & 0xF8) >> 3));
	}
	return 0;
}

static void draw_block(uint8_t *fb, int stride, int fb_width, int fb_height,
	int bpp, int x, int y, int block_w, int block_h, uint32_t color)
{
	if (block_w <= 0 || block_h <= 0) {
		return;
	}
	if (x >= fb_width || y >= fb_height) {
		return;
	}
	if (x + block_w > fb_width) {
		block_w = fb_width - x;
	}
	if (y + block_h > fb_height) {
		block_h = fb_height - y;
	}

	if (bpp == 32) {
		for (int row = 0; row < block_h; ++row) {
			uint32_t *dst = (uint32_t *)(fb + (y + row) * stride);
			dst += x;
			for (int col = 0; col < block_w; ++col) {
				dst[col] = color;
			}
		}
	} else {
		uint16_t color16 = (uint16_t)color;
		for (int row = 0; row < block_h; ++row) {
			uint16_t *dst = (uint16_t *)(fb + (y + row) * stride);
			dst += x;
			for (int col = 0; col < block_w; ++col) {
				dst[col] = color16;
			}
		}
	}
}

static void fill_screen(uint8_t *fb, int stride, int fb_width, int fb_height,
	int bpp, uint32_t color)
{
	draw_block(fb, stride, fb_width, fb_height, bpp, 0, 0, fb_width, fb_height, color);
}

static void draw_char(uint8_t *fb, int stride, int fb_width, int fb_height,
	int bpp, int x, int y, int scale, uint32_t color, const uint8_t *rows)
{
	for (int row = 0; row < GLYPH_H; ++row) {
		uint8_t bits = rows[row];
		for (int col = 0; col < GLYPH_W; ++col) {
			if ((bits & (1 << (GLYPH_W - 1 - col))) == 0) {
				continue;
			}
			int px = x + col * scale;
			int py = y + row * scale;
			draw_block(fb, stride, fb_width, fb_height, bpp, px, py, scale, scale, color);
		}
	}
}

static void announce_ready(void)
{
	FILE *fp = fopen("/proc/uptime", "r");
	if (!fp) {
		printf("[BOOT] GUI ready (uptime unavailable): %s\n", strerror(errno));
		fflush(stdout);
		return;
	}

	double uptime = 0.0;
	if (fscanf(fp, "%lf", &uptime) == 1) {
		printf("[BOOT] GUI ready at %6.3fs\n", uptime);
	} else {
		printf("[BOOT] GUI ready (uptime unavailable)\n");
	}
	fclose(fp);
	fflush(stdout);
}

static void render_clock(uint8_t *fb, int stride, int fb_width, int fb_height,
	int bpp, uint32_t fg, uint32_t bg, const char *text)
{
	int len = (int)strlen(text);
	if (len == 0) {
		return;
	}

	int scale = fb_width / (len * (GLYPH_W + 1));
	int max_height_scale = fb_height / (GLYPH_H + 2);
	if (scale == 0 || scale > max_height_scale) {
		scale = max_height_scale;
	}
	if (scale < 1) {
		scale = 1;
	}

	int char_width = GLYPH_W * scale;
	int char_height = GLYPH_H * scale;
	int total_width = len * char_width + (len - 1) * scale;
	while (total_width > fb_width && scale > 1) {
		--scale;
		char_width = GLYPH_W * scale;
		char_height = GLYPH_H * scale;
		total_width = len * char_width + (len - 1) * scale;
	}

	int origin_x = fb_width > total_width ? (fb_width - total_width) / 2 : 0;
	int origin_y = fb_height > char_height ? (fb_height - char_height) / 2 : 0;

	fill_screen(fb, stride, fb_width, fb_height, bpp, bg);

	for (int i = 0; i < len; ++i) {
		const uint8_t *rows = lookup_glyph(text[i]);
		int x = origin_x + i * (char_width + scale);
		draw_char(fb, stride, fb_width, fb_height, bpp, x, origin_y, scale, fg, rows);
	}

	msync(fb, (size_t)stride * fb_height, MS_ASYNC);
}

int main(void)
{
	signal(SIGTERM, handle_signal);
	signal(SIGINT, handle_signal);
	signal(SIGQUIT, handle_signal);

	if (wait_for_framebuffer(FB_PATH, WAIT_TIMEOUT_SECONDS) != 0) {
		fprintf(stderr, "[BOOT] GUI failed: framebuffer missing\n");
		return 1;
	}

	int fd = open(FB_PATH, O_RDWR);
	if (fd < 0) {
		fprintf(stderr, "[BOOT] GUI failed: %s\n", strerror(errno));
		return 1;
	}

	struct fb_fix_screeninfo fix;
	struct fb_var_screeninfo var;
	if (ioctl(fd, FBIOGET_FSCREENINFO, &fix) != 0 ||
	    ioctl(fd, FBIOGET_VSCREENINFO, &var) != 0) {
		fprintf(stderr, "[BOOT] GUI failed: fb ioctl error\n");
		close(fd);
		return 1;
	}

	if (var.bits_per_pixel != 16 && var.bits_per_pixel != 32) {
		fprintf(stderr, "[BOOT] GUI failed: unsupported bpp %u\n", var.bits_per_pixel);
		close(fd);
		return 1;
	}

	size_t map_size = fix.smem_len;
	if (map_size == 0) {
		map_size = (size_t)fix.line_length * var.yres;
	}

	uint8_t *fb = mmap(NULL, map_size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
	if (fb == MAP_FAILED) {
		fprintf(stderr, "[BOOT] GUI failed: mmap error %s\n", strerror(errno));
		close(fd);
		return 1;
	}

	close(fd);

	const int stride = fix.line_length;
	const int fb_width = (int)var.xres;
	const int fb_height = (int)var.yres;
	const int bpp = (int)var.bits_per_pixel;
	const uint32_t fg = pack_color(bpp, 38, 194, 129);
	const uint32_t bg = pack_color(bpp, 32, 32, 32);

	char last_render[16] = "";
	int ready_announced = 0;

	while (!g_stop) {
		time_t raw = time(NULL);
		struct tm tm_now;
		if (localtime_r(&raw, &tm_now) == NULL) {
			continue;
		}

		char timestamp[16];
		if (strftime(timestamp, sizeof(timestamp), "%H:%M:%S", &tm_now) == 0) {
			continue;
		}

		if (strcmp(timestamp, last_render) != 0) {
			render_clock(fb, stride, fb_width, fb_height, bpp, fg, bg, timestamp);
			strncpy(last_render, timestamp, sizeof(last_render));
			last_render[sizeof(last_render) - 1] = '\0';
			if (!ready_announced) {
				announce_ready();
				ready_announced = 1;
			}
		}

		struct timespec sleep_ts = { 0, 200000000L };
		nanosleep(&sleep_ts, NULL);
	}

	munmap(fb, map_size);
	return 0;
}
