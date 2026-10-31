#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

WRT_IP='192.168.11.1'
WRT_HOSTNAME='TENDA'
WRT_SSID='Tenda'

CFG_FILE='./package/base-files/files/bin/config_generate'
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_HOSTNAME'/g" $CFG_FILE
#修改WIFI名称
sed -i "s/ImmortalWrt-/${WRT_SSID}_/g" ./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
#修改国家
sed -i "s/.country=US/.country=CN/g" ./package/mtk/applications/mtwifi-cfg/files/mtwifi.sh
#修改默认IP地址
sed -i "s/192\.168\.[0-9][0-9]*\.[0-9][0-9]*/$WRT_IP/g" $CFG_FILE
#修改immortalwrt.lan关联IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -Ei "s/192\.168\.[0-9][0-9]*\.[0-9][0-9]*/$WRT_IP/g" {} +

WIFI_UC='./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc'
if [ -f "$WIFI_UC" ]; then
	#修改WIFI名称
	sed -i "s/defaults?.ssid || \"ImmortalWrt\"/defaults?.ssid || \"$WRT_SSID\"/g" $WIFI_UC
	#修改WIFI密码
	sed -i "s/key='.*'/key=''/g" $WIFI_UC
	#国家
	sed -i "s/country || ''/country || 'CN'/g" $WIFI_UC
fi

#移除luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
#修改默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' ./feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local PKG_LIST=("$PKG_NAME" $5)  # 第5个参数为自定义名称列表
	local REPO_NAME=${PKG_REPO#*/}
	local REPO_PATH="./package/$REPO_NAME"

	echo " "

	# 删除本地可能存在的不同名称的软件包
	for NAME in "${PKG_LIST[@]}"; do
		# 查找匹配的目录
		echo "Search directory: $NAME"
		local FOUND_DIRS=$(find ./feeds/luci/ ./feeds/packages/ -maxdepth 3 -type d -iname "*$NAME*" 2>/dev/null)

		# 删除找到的目录
		if [ -n "$FOUND_DIRS" ]; then
			while read -r DIR; do
				rm -rf "$DIR"
				echo "Delete directory: $DIR"
			done <<< "$FOUND_DIRS"
		else
			echo "Not fonud directory: $NAME"
		fi
	done

	# 克隆 GitHub 仓库
	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git" $REPO_PATH

	# 处理克隆的仓库
	if [[ "$PKG_SPECIAL" == "pkg" ]]; then
		find $REPO_PATH/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune -exec cp -rf {} ./package \;
		rm -rf $REPO_PATH
	fi
}

# Update packages
#UPDATE_PACKAGE "nas" "linkease/nas-packages" "master"
#UPDATE_PACKAGE "nas_luci" "linkease/nas-packages-luci" "main"
#UPDATE_PACKAGE "openappfilter" "destan19/OpenAppFilter" "master" "" "appfilter oaf"
UPDATE_PACKAGE "luci-theme-footstrap" "VizzleTF/luci-theme-footstrap" "main"
UPDATE_PACKAGE "tailscale" "GuNanOvO/openwrt-tailscale" "main" "pkg" "tailscale"
UPDATE_PACKAGE "luci-app-tailscale-community" "Tokisaki-Galaxy/luci-app-tailscale-community" "master" "" "luci-app-tailscale-community"
UPDATE_PACKAGE "luciapp-adguardhome" "stevenjoezhang/luci-app-adguardhome" "dev" "" "luci-app-adguardhome"
UPDATE_PACKAGE "nikki" "nikkinikki-org/OpenWrt-nikki" "main"

# Proceed package files
sed -i 's/PKG_BUILD_VERSION:=.*/PKG_BUILD_VERSION:=v1.19.29/g' ./package/OpenWrt-nikki/mihomo-meta/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=v1.19.29/g' ./package/OpenWrt-nikki/mihomo-meta/Makefile
sed -i '/CONFLICTS:=mihomo-/d' ./package/OpenWrt-nikki/mihomo-meta/Makefile ./package/OpenWrt-nikki/mihomo-alpha/Makefile
sed -i \
  -e 's/ (OpenWrt-UPX)//g' \
  -e 's/ (UPX Compressed)//g' \
  -e '/^ifneq ($(filter mips64% riscv64% loongarch64%,$(ARCH)),)/,/^endif$/d' \
  -e '/^ifneq ($(DISABLE_UPX),1)/,/^endif$/d' \
  ./package/tailscale/Makefile

# Enable packages
MODEL_CONFIG_FILE='./defconfig/minimal.config'
echo >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_kmod-mtd-rw=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_LUCI_LANG_zh_Hans=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-app-wol=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-app-tailscale-community=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-app-adguardhome=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-compat=y' >> $MODEL_CONFIG_FILE
#echo 'CONFIG_PACKAGE_adguardhome=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_mihomo-meta=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_mihomo-alpha=n' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-app-nikki=y' >> $MODEL_CONFIG_FILE
#echo 'CONFIG_PACKAGE_luci-app-oaf=y' >> $MODEL_CONFIG_FILE
sed -i '/luci-theme-argon/d' $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-theme-bootstrap=y' >> $MODEL_CONFIG_FILE
echo 'CONFIG_PACKAGE_luci-theme-footstrap=y' >> $MODEL_CONFIG_FILE
echo >> $MODEL_CONFIG_FILE


cat << EOFF > package/base-files/files/etc/uci-defaults/95-custom-settings

uci -q batch <<-EOF
	set system.@system[0].log_size='128'
	set system.@system[0].conloglevel='5'
	commit system
EOF

if [ -d /www/luci-static/footstrap ]; then
    uci -q set luci.main.mediaurlbase='/luci-static/footstrap'
    uci -q commit luci
fi

exit 0

EOFF

# 手动调整插件
if [ -n "$WRT_PKG" ]; then
	echo -e "$WRT_PKG" >> ./.config
fi

# UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg，可选，从大杂烩中单独提取包名插件"
# 调用示例
# UPDATE_PACKAGE "OpenAppFilter" "destan19/OpenAppFilter" "master" "" "custom_name1 custom_name2"
# UPDATE_PACKAGE "open-app-filter" "destan19/OpenAppFilter" "master" "" "luci-app-appfilter oaf" 这样会把原有的open-app-filter，luci-app-appfilter，oaf相关组件删除，不会出现coremark错误。

# UPDATE_PACKAGE "aurora" "eamonxg/luci-theme-aurora" "master"
# UPDATE_PACKAGE "aurora-config" "eamonxg/luci-app-aurora-config" "master"
# UPDATE_PACKAGE "fluent" "LazuliKao/luci-theme-fluent" "main"
# UPDATE_PACKAGE "footstrap" "VizzleTF/luci-theme-footstrap" "main"
# UPDATE_PACKAGE "kucat" "sirpdboy/luci-theme-kucat" "master"
# UPDATE_PACKAGE "kucat-config" "sirpdboy/luci-app-kucat-config" "master"
# UPDATE_PACKAGE "shadcn" "eamonxg/luci-theme-shadcn" "main"
# UPDATE_PACKAGE "momo" "nikkinikki-org/OpenWrt-momo" "main"

# UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
# UPDATE_PACKAGE "passwall" "Openwrt-Passwall/openwrt-passwall" "main" "pkg"
# UPDATE_PACKAGE "passwall2" "Openwrt-Passwall/openwrt-passwall2" "main" "pkg"
#
# UPDATE_PACKAGE "diskmanager" "4IceG/luci-app-mini-diskmanager" "main"
# UPDATE_PACKAGE "easytier" "EasyTier/luci-app-easytier" "main"
# UPDATE_PACKAGE "qmodem" "FUjr/QModem" "main"
# UPDATE_PACKAGE "viking" "VIKINGYFY/packages" "main" "" "axonhub gecoosac sing-box luci-app-homeproxy luci-app-timewol luci-app-wolplus luci-app-wolultra"
# UPDATE_PACKAGE "vnt" "lmq8267/luci-app-vnt" "main"
#
# UPDATE_PACKAGE "diskman" "sbwml/luci-app-diskman" "main"
# UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5" "" "v2dat"
# UPDATE_PACKAGE "openlist2" "sbwml/luci-app-openlist2" "main"
# UPDATE_PACKAGE "qbittorrent" "sbwml/luci-app-qbittorrent" "master" "" "qt6base qt6tools rblibtorrent"
# UPDATE_PACKAGE "quickfile" "sbwml/luci-app-quickfile" "main"
#
# UPDATE_PACKAGE "ddns-go" "sirpdboy/luci-app-ddns-go" "main"
# UPDATE_PACKAGE "netspeedtest" "sirpdboy/netspeedtest" "main" "" "homebox ookla-speedtest"
# UPDATE_PACKAGE "netwizard" "sirpdboy/luci-app-netwizard" "main"
# UPDATE_PACKAGE "partexp" "sirpdboy/luci-app-partexp" "main"
# UPDATE_PACKAGE "timecontrol" "sirpdboy/luci-app-timecontrol" "main"
#
# UPDATE_PACKAGE "natmapt" "muink/openwrt-natmapt" "master"
# UPDATE_PACKAGE "stuntman" "muink/openwrt-stuntman" "master"
# UPDATE_PACKAGE "luci-app-natmapt" "muink/luci-app-natmapt" "master"
#
# UPDATE_PACKAGE "airpi3000m-fancontrol" "LianXia233/luci-app-airpi3000m-fancontrol" "main"
# UPDATE_PACKAGE "chfs" "LianXia233/luci-app-chfs" "main"
# UPDATE_PACKAGE "fm350" "LianXia233/luci-app-fm350" "main"
# UPDATE_PACKAGE "h5000m-netmode" "LianXia233/luci-app-h5000m-netmode" "main"
# UPDATE_PACKAGE "mt5700" "LianXia233/luci-app-mt5700" "main"
# UPDATE_PACKAGE "mt5700m" "LianXia233/luci-app-mt5700m" "main"
# UPDATE_PACKAGE "netmonitor" "LianXia233/luci-app-netmonitor" "main"
# UPDATE_PACKAGE "qmodem-generic" "LianXia233/luci-app-qmodem-generic" "main"
#