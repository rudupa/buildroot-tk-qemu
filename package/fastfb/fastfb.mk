################################################################################
# fastfb
################################################################################

FASTFB_VERSION = 0.1
FASTFB_SITE = $(TOPDIR)/package/fastfb
FASTFB_SITE_METHOD = local
FASTFB_LICENSE = MIT
FASTFB_LICENSE_FILES = LICENSE

FASTFB_DEPENDENCIES =

define FASTFB_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) -Os -ffunction-sections -fdata-sections \
		$(TARGET_LDFLAGS) -Wl,--gc-sections -o $(@D)/fastfb \
		$(@D)/fastfb.c
endef

define FASTFB_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/fastfb $(TARGET_DIR)/usr/bin/fastfb
	$(TARGET_STRIP) $(TARGET_DIR)/usr/bin/fastfb 2>/dev/null || true
endef

$(eval $(generic-package))
