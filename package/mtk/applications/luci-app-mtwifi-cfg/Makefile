#
# Copyright (C) hanwckf <hanwckf@vip.qq.com>
#
# This is free software, licensed under the GNU General Public License v2.
#

include $(TOPDIR)/rules.mk

# Rescan after LuCI feeds arrive if the initial package scan ran before them.
SCAN_DEPS = $(TOPDIR)/feeds/luci/luci.mk

LUCI_TITLE:=LuCI support for mtwifi-cfg
LUCI_DEPENDS:=+luci-mod-network +mtwifi-cfg-ucode +rpcd-mod-ucode +rpcd-mod-iwinfo
LUCI_PKGARCH:=all

PKG_VERSION:=1

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
