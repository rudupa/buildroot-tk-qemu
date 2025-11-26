################################################################################
# Tk
################################################################################

TK_VERSION = 8.6.17
TK_SITE = https://prdownloads.sourceforge.net/tcl
TK_SOURCE = tk$(TK_VERSION)-src.tar.gz
TK_LICENSE = Tcl/Tk license
TK_LICENSE_FILES = license.terms
TK_SUBDIR = unix

TK_DEPENDENCIES = tcl xlib_libX11

TK_INSTALL_STAGING = YES

TK_AUTORECONF = NO

TK_CONF_OPTS = \
        --with-tcl=$(STAGING_DIR)/usr/lib \
        --prefix=/usr

$(eval $(autotools-package))
