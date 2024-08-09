#!/bin/bash

# 这条注释只是为了触发编译

# 自定义feed源
cp -rf ../feeds.conf.default ./feeds.conf.default
# 更新 Feeds
./scripts/feeds update -a >/dev/null
./scripts/feeds install -a >/dev/null
# 可删除的

uneedpkg="luci-app-appfilter mdio-tools mdio-netlink libpfring ovpn-dco jool xr_usb_serial_common open-app-filter openvpn freeswitch luci-app-openvpn-server freetdm freeswitch-mod-bcg729"
uneedpkg="$uneedpkg luci-app-openclash luci-app-netdata"

./scripts/feeds uninstall $uneedpkg >/dev/null
### 获取额外的 LuCI 应用、主题和依赖 ###
# 源码
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash.git ./package/new/luci-app-openclash >/dev/null
git clone --depth 1 https://github.com/sirpdboy/sirpdboy-package.git ./package/sirpdboy-package >/dev/null
rm -rf ./package/sirpdboy-package/luci-app-control-timewol

# 滚回修复无法编译的
mkdir -p ./2305packages/
git clone -b openwrt-23.05 --depth 1 https://github.com/immortalwrt/packages.git ./2305packages >/dev/null
rm -rf ./feeds/packages/lang/ruby
cp -rf ./2305packages/lang/ruby ./feeds/packages/lang/ruby

# 必要 Patch
cp -rf ../PATCH/attr/200-basename.patch ./feeds/packages/utils/attr/patches/

# Patch LuCI 以支持自定义 nft 规则
patch -p1 <../PATCH/fw4/100-openwrt-firewall4-add-custom-nft-command-support.patch

pushd feeds/luci # 临时进入 ./feeds/luci
patch -p1 <../../../PATCH/fw4/04-luci-add-firewall4-nft-rules-file.patch
popd # 回到原目录

### 最后的收尾工作 ###
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf

# 修改默认ip
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
# 修改默认主机名
sed -i 's/ImmortalWrt/LynnOS/g' package/base-files/files/bin/config_generate
sed -i 's/ImmortalWrt/LynnOS/g' package/network/config/wifi-scripts/files/lib/wifi/mac80211.sh

# 预配置文件
cp -rf ../PATCH/files ./

chmod +x files/etc/init.d/youhua

wait
