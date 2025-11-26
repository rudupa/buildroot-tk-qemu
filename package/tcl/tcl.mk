################################################################################
# tcl
################################################################################

TCL_VERSION_MAJOR = 8.6
TCL_VERSION = $(TCL_VERSION_MAJOR).15
TCL_SOURCE = tcl$(TCL_VERSION)-src.tar.gz
TCL_SITE = http://downloads.sourceforge.net/project/tcl/Tcl/$(TCL_VERSION)
TCL_LICENSE = TCL
TCL_LICENSE_FILES = license.terms
TCL_CPE_ID_VENDOR = tcl
TCL_SUBDIR = unix

TCL_INSTALL_STAGING = YES
TCL_AUTORECONF = YES

# Tcl's install step duplicates the full build output path below STAGING_DIR;
# drop the extra tree so the staging sanity check passes.
define TCL_REMOVE_STAGING_O_DIR
    rm -rf $(STAGING_DIR)/$(O)
endef
TCL_POST_INSTALL_STAGING_HOOKS += TCL_REMOVE_STAGING_O_DIR

# When cross-compiling, Buildroot forbids host library paths such as -L/usr/lib.
# Strip those from the Tcl config scripts so dependent packages (e.g. Tk) build cleanly.
define TCL_SANITIZE_CONFIG_LIBPATH
    if [ -f $(STAGING_DIR)/usr/lib/tclConfig.sh ]; then \
        $(SED) 's@-L/usr/lib@@g' $(STAGING_DIR)/usr/lib/tclConfig.sh; \
    fi
    if [ -f $(STAGING_DIR)/usr/lib/tclooConfig.sh ]; then \
        $(SED) 's@-L/usr/lib@@g' $(STAGING_DIR)/usr/lib/tclooConfig.sh; \
    fi
endef
TCL_POST_INSTALL_STAGING_HOOKS += TCL_SANITIZE_CONFIG_LIBPATH

# ------------------------------------------------------------------------------
# Configure options for target TCL
# IMPORTANT: Target prefix is /usr (never $(STAGING_DIR))
# ------------------------------------------------------------------------------
TCL_CONF_OPTS = \
    --enable-shared \
    --enable-stubs \
    --prefix=/usr

# ------------------------------------------------------------------------------
# Configure options for HOST TCL
# HOST prefix must be $(HOST_DIR)/usr
# ------------------------------------------------------------------------------

HOST_TCL_CONF_OPTS = \
    --enable-shared \
    --enable-stubs \
    --prefix=$(HOST_DIR)/usr

# ------------------------------------------------------------------------------
# Remove bundled sqlite / TDBC packages (Buildroot prefers external ones)
# ------------------------------------------------------------------------------

define HOST_TCL_REMOVE_PACKAGES
    rm -fr $(@D)/pkgs/sqlite3* \
           $(@D)/pkgs/tdbc*
endef
HOST_TCL_PRE_CONFIGURE_HOOKS += HOST_TCL_REMOVE_PACKAGES

define TCL_REMOVE_PACKAGES
    rm -fr $(@D)/pkgs/sqlite3* \
        $(if $(BR2_PACKAGE_MARIADB),,$(@D)/pkgs/tdbcmysql*) \
        $(@D)/pkgs/tdbcodbc* \
        $(if $(BR2_PACKAGE_POSTGRESQL),,$(@D)/pkgs/tdbcpostgres*) \
        $(if $(BR2_PACKAGE_SQLITE),,$(@D)/pkgs/tdbcsqlite3*)
endef
TCL_PRE_CONFIGURE_HOOKS += TCL_REMOVE_PACKAGES

# ------------------------------------------------------------------------------
# Optional encodings removal (size reduction)
# ------------------------------------------------------------------------------
ifeq ($(BR2_PACKAGE_TCL_DEL_ENCODINGS),y)
define TCL_REMOVE_ENCODINGS
    rm -rf $(TARGET_DIR)/usr/lib/tcl$(TCL_VERSION_MAJOR)/encoding/*
endef
TCL_POST_INSTALL_TARGET_HOOKS += TCL_REMOVE_ENCODINGS
endif

# ------------------------------------------------------------------------------
# tclsh handling
# ------------------------------------------------------------------------------
ifeq ($(BR2_PACKAGE_TCL_SHLIB_ONLY),y)
define TCL_REMOVE_TCLSH
    rm -f $(TARGET_DIR)/usr/bin/tclsh$(TCL_VERSION_MAJOR)
endef
TCL_POST_INSTALL_TARGET_HOOKS += TCL_REMOVE_TCLSH
else
define TCL_SYMLINK_TCLSH
    ln -sf tclsh$(TCL_VERSION_MAJOR) $(TARGET_DIR)/usr/bin/tclsh
endef
TCL_POST_INSTALL_TARGET_HOOKS += TCL_SYMLINK_TCLSH
endif

# ------------------------------------------------------------------------------
# Remove files ONLY from TARGET — NOT staging!
# Tk requires tclConfig.sh during its configure stage.
# ------------------------------------------------------------------------------
define TCL_REMOVE_EXTRA_TARGET
    rm -fr $(TARGET_DIR)/usr/lib/tclConfig.sh \
           $(TARGET_DIR)/usr/lib/tclooConfig.sh \
           $(TARGET_DIR)/usr/lib/tcl$(TCL_VERSION_MAJOR)/tclAppInit.c \
           $(TARGET_DIR)/usr/lib/tcl$(TCL_VERSION_MAJOR)/msgs
endef
TCL_POST_INSTALL_TARGET_HOOKS += TCL_REMOVE_EXTRA_TARGET

# ------------------------------------------------------------------------------
# Dependencies
# ------------------------------------------------------------------------------
TCL_DEPENDENCIES = \
    zlib \
    $(if $(BR2_PACKAGE_SQLITE),sqlite) \
    $(if $(BR2_PACKAGE_MARIADB),mariadb) \
    $(if $(BR2_PACKAGE_POSTGRESQL),postgresql)

$(eval $(autotools-package))
$(eval $(host-autotools-package))
