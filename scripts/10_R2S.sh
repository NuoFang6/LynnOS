echo "权限状态："
ls -l $wrtdir
id

clone() {
  #* 参数1是分支名，参数2是仓库地址，参数3是目标目录
  branch_name=$1
  repo_url=$2
  target_dir=$3
  git clone -q -b $branch_name --depth 1 --single-branch --no-tags $repo_url $target_dir # 克隆仓库到目标目录，并指定分支名和深度为1
}

cd $wrtdir
echo "进入wrt根目录：$wrtdir"


# echo "自定义feed源"
# cp -rf ${lynndir}/scripts/feeds.conf.default ./feeds.conf.default


echo "更新 Feeds"
./scripts/feeds update -a 2>&1 | grep -i "WARNING"
./scripts/feeds install -a 2>&1 | grep -i "WARNING"


# echo "移除问题软件包"
# 缺少依赖的包
# uneedpkg="$uneedpkg luci-app-qbittorrent qBittorrent-Enhanced-Edition bcm27xx-eeprom boost efibootmgr freeswitch mc micropython-lib owut python-gmpy2 pdns mpd netwhere libtorrent-rasterbar kea i2pd hyperscan freetdm domoticz dnsdist pdns-recursor schroot trojan trojan-plus luci-app-passwall libmpc freeswitch-mod-bcg729 snort3 openappid"
#
# ./scripts/feeds uninstall -f $uneedpkg 2>&1 | grep -i "WARNING"


echo "替换包"
./scripts/feeds uninstall -f luci-app-openclash 2>&1 | grep -i "WARNING"
clone dev https://github.com/vernesong/OpenClash.git ./package/luci-app-openclash &

echo "获取额外的软件包"
clone master https://github.com/qwq233/UA4F.git ./package/ua4f &
clone main https://github.com/morytyann/OpenWrt-mihomo.git ./package/MihomoTProxy &
# cp -rf ./masterImmortalWrt/package/emortal/cpufreq ./package/emortal/
# cp -rf ./2305packages/lang/ruby ./package/
# rm -rf ./package/utils/util-linux && cp -rf ./masterImmortalWrt/package/utils/util-linux ./package/utils/

echo "下载其他仓库"
clone openwrt-23.05 https://github.com/immortalwrt/packages.git ./2305packages &
clone master https://github.com/immortalwrt/immortalwrt.git ./masterImmortalWrt &
clone 24.10 https://github.com/QiuSimons/YAOF.git ./YAOF &
clone master https://github.com/coolsnowwolf/lede.git ../lede &
wait # 等待后台全部完成



echo "预配置文件"
cp -rf ${lynndir}/files ./
chmod +x ./files/etc/init.d/youhua
#
cp -rf ${lynndir}/seed/R2S/seed.config ./.config
# cp -rf ${lynndir}/seed/R2S/config-6.6 ./target/linux/rockchip/armv8/



#* Patchs
echo "修复编译问题"
cp -rf ${lynndir}/patch/attr/200-basename.patch ./feeds/packages/utils/attr/patches/
cp -rf ${lynndir}/patch/samba4/099-fix-librpc-missing-config-h.patch ./feeds/packages/net/samba4/patches/
#
patch -p1 <${lynndir}/patch/qt6/qt6base_disable_lto.patch
#
patch -p1 <${lynndir}/patch/libffi/libffi.patch
# openssl disable LTO
sed -i 's,no-mips16 gc-sections,no-mips16 gc-sections no-lto,g' package/libs/openssl/Makefile
# libsodium
sed -i 's,no-mips16,no-mips16 no-lto,g' feeds/packages/libs/libsodium/Makefile


echo "功能增强Patch"
#* 来源 YAOF https://github.com/QiuSimons/YAOF
mv -f ./YAOF/PATCH ../
### 必要的 Patches ###
# TCP optimizations
cp -rf ../PATCH/kernel/6.7_Boost_For_Single_TCP_Flow/* ./target/linux/generic/backport-6.6/
cp -rf ../PATCH/kernel/6.8_Boost_TCP_Performance_For_Many_Concurrent_Connections-bp_but_put_in_hack/* ./target/linux/generic/hack-6.6/
cp -rf ../PATCH/kernel/6.8_Better_data_locality_in_networking_fast_paths-bp_but_put_in_hack/* ./target/linux/generic/hack-6.6/
# UDP optimizations
cp -rf ../PATCH/kernel/6.7_FQ_packet_scheduling/* ./target/linux/generic/backport-6.6/
# Patch arm64 型号名称
cp -rf ../PATCH/kernel/arm/* ./target/linux/generic/hack-6.6/
# BBRv3
cp -rf ../PATCH/kernel/bbr3/* ./target/linux/generic/backport-6.6/
# LRNG
cp -rf ../PATCH/kernel/lrng/* ./target/linux/generic/hack-6.6/
echo '
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
CONFIG_LRNG_DEV_IF=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
CONFIG_LRNG_SELFTEST=y
# CONFIG_LRNG_SELFTEST_PANIC is not set
' >>./target/linux/generic/config-6.6
# wg
cp -rf ../PATCH/kernel/wg/* ./target/linux/generic/hack-6.6/
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# OTHERS
# cp -rf ../PATCH/kernel/others/* ./target/linux/generic/pending-6.6/ #* 999-net-net-fix-data-races-around-sk--sk_forward_alloc.patch 无法应用
### Fullcone-NAT 部分 ###
# bcmfullcone
cp -rf ../PATCH/kernel/bcmfullcone/* ./target/linux/generic/hack-6.6/
# set nf_conntrack_expect_max for fullcone
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# FW4
mkdir -p package/network/config/firewall4/patches
cp -f ../PATCH/pkgs/firewall/firewall4_patches/*.patch ./package/network/config/firewall4/patches/
mkdir -p package/libs/libnftnl/patches
cp -f ../PATCH/pkgs/firewall/libnftnl/*.patch ./package/libs/libnftnl/patches/
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
mkdir -p package/network/utils/nftables/patches
cp -f ../PATCH/pkgs/firewall/nftables/*.patch ./package/network/utils/nftables/patches/
# Patch LuCI 以增添 FullCone 开关
pushd feeds/luci
patch -p1 <../../../PATCH/pkgs/firewall/luci/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
popd
### Shortcut-FE 部分 ###
# Patch Kernel 以支持 Shortcut-FE
cp -rf ../PATCH/kernel/sfe/* ./target/linux/generic/hack-6.6/
cp -rf ../lede/target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch ./target/linux/generic/pending-6.6/613-netfilter_optional_tcp_window_check.patch
# Patch LuCI 以增添 Shortcut-FE 开关
pushd feeds/luci
patch -p1 <../../../PATCH/pkgs/firewall/luci/0002-luci-app-firewall-add-shortcut-fe-option.patch
popd
### NAT6 部分 ###
# custom nft command
patch -p1 < ../PATCH/pkgs/firewall/100-openwrt-firewall4-add-custom-nft-command-support.patch
# Patch LuCI 以增添 NAT6 开关
pushd feeds/luci
patch -p1 <../../../PATCH/pkgs/firewall/luci/0003-luci-app-firewall-add-ipv6-nat-option.patch
popd
# Patch LuCI 以支持自定义 nft 规则
pushd feeds/luci
patch -p1 <../../../PATCH/pkgs/firewall/luci/0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd
### natflow 部分 ###
pushd feeds/luci
patch -p1 <../../../PATCH/pkgs/firewall/luci/0005-luci-app-firewall-add-natflow-offload-support.patch
popd
### fullcone6 ###
pushd feeds/luci
patch -p1 <../../../PATCH/pkgs/firewall/luci/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch
popd
### Other Kernel Hack 部分 ###
# make olddefconfig
wget -qO - https://github.com/openwrt/openwrt/commit/c21a3570.patch | patch -p1
# igc-fix
cp -rf ../lede/target/linux/x86/patches-6.6/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-6.6/996-intel-igc-i225-i226-disable-eee.patch
# btf
cp -rf ../PATCH/kernel/btf/* ./target/linux/generic/hack-6.6/
#
cp -rf ../PATCH/kernel/rockchip/* ./target/linux/rockchip/patches-6.6/
wget https://github.com/immortalwrt/immortalwrt/raw/refs/tags/v23.05.4/target/linux/rockchip/patches-5.15/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch -O target/linux/rockchip/patches-6.6/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch
#
# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript
#
# mount cgroupv2
pushd feeds/packages
patch -p1 <../../../PATCH/pkgs/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ../PATCH/pkgs/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ../PATCH/pkgs/cgroupfs-mount/901-fix-cgroupfs-umount.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ../PATCH/pkgs/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch ./feeds/packages/utils/cgroupfs-mount/patches/
# fstool
wget -qO - https://github.com/coolsnowwolf/lede/commit/8a4db76.patch | patch -p1
#
# IPv6 兼容助手
patch -p1 <../PATCH/pkgs/odhcp6c/1002-odhcp6c-support-dhcpv6-hotplug.patch
# ODHCPD
mkdir -p package/network/services/odhcpd/patches
cp -f ../PATCH/pkgs/odhcpd/0001-odhcpd-improve-RFC-9096-compliance.patch ./package/network/services/odhcpd/patches/0001-odhcpd-improve-RFC-9096-compliance.patch
mkdir -p package/network/ipv6/odhcp6c/patches
wget https://github.com/openwrt/odhcp6c/pull/75.patch -O package/network/ipv6/odhcp6c/patches/75.patch
wget https://github.com/openwrt/odhcp6c/pull/80.patch -O package/network/ipv6/odhcp6c/patches/80.patch
wget https://github.com/openwrt/odhcp6c/pull/82.patch -O package/network/ipv6/odhcp6c/patches/82.patch
wget https://github.com/openwrt/odhcp6c/pull/83.patch -O package/network/ipv6/odhcp6c/patches/83.patch
wget https://github.com/openwrt/odhcp6c/pull/84.patch -O package/network/ipv6/odhcp6c/patches/84.patch
wget https://github.com/openwrt/odhcp6c/pull/90.patch -O package/network/ipv6/odhcp6c/patches/90.patch
#
#Vermagic # 内核模块兼容
wget https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/targets/rockchip/armv8/profiles.json
jq -r '.linux_kernel.vermagic' profiles.json >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk


# 自定义 Patch
# patch -p1 <$lynndir/patch/target/target_r2s.patch
# patch -p1 <$lynndir/patch/squashfs/add_zstd_support.patch

echo "修改源码"
# 修改默认ip
sed -i 's/192.168.1.1/192.168.2.1/g' ./package/base-files/files/bin/config_generate
# 交换 LAN/WAN 口
sed -i 's,"eth1" "eth0","eth0" "eth1",g' ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
# 强制使用 O3 级别的优化
sed -i 's/-Os/-O3/g' ./include/target.mk
# 使用专属优化
sed -i 's,CPU_TYPE ?= generic,CPU_TYPE ?= cortex-a53,g' include/target.mk
sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mtune=cortex-a53 -mcpu=cortex-a53+crypto+crc,g' include/target.mk
sed -i 's,-mcpu=cortex-a53,-march=armv8-a+crypto+crc -mtune=cortex-a53 -mcpu=cortex-a53+crypto+crc,g' include/target.mk
# 移除 SNAPSHOT 标签
sed -i 's,-SNAPSHOT,,g' include/version.mk
sed -i 's,-SNAPSHOT,,g' package/base-files/image-config.in
sed -i '/CONFIG_BUILDBOT/d' include/feeds.mk
sed -i 's/;)\s*\\/; \\/' include/feeds.mk


echo "清理未使用的文件"
rm -rf ./2305packages
rm -rf ./masterimmortalwrt
rm -rf ./YAOF
rm -rf ../lede