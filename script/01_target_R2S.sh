#!/bin/bash
#* 脚本将在 immortalWrt 目录下运行
# /home/runner/work/LynnOS/immortalWrt
opath="/home/runner/work/LynnOS/LynnOS"
clone() {
  #* 参数1是分支名，参数2是仓库地址，参数3是目标目录
  branch_name=$1
  repo_url=$2
  target_dir=$3
  # 克隆仓库到目标目录，并指定分支名和深度为1
  git clone -q -b $branch_name --depth 1 --single-branch --no-tags $repo_url $target_dir

}

#* 自定义feed源
cp -rf $opath/script/feeds.conf.default ./feeds.conf.default

#* 更新 Feeds
./scripts/feeds update -a 2>&1 | grep -i "WARNING"
./scripts/feeds install -a 2>&1 | grep -i "WARNING"

#* 移除无用软件包
# 需要替换的包
uneedpkg="luci-app-openclash"
# 缺少依赖的包
# uneedpkg="$uneedpkg luci-app-qbittorrent qBittorrent-Enhanced-Edition bcm27xx-eeprom boost efibootmgr freeswitch mc micropython-lib owut python-gmpy2 pdns mpd netwhere libtorrent-rasterbar kea i2pd hyperscan freetdm domoticz dnsdist pdns-recursor schroot trojan trojan-plus luci-app-passwall libmpc freeswitch-mod-bcg729 snort3 openappid"
#
./scripts/feeds uninstall $uneedpkg 2>&1 | grep -i "WARNING"

#* 获取额外的软件包
clone openwrt-23.05 https://github.com/immortalwrt/packages.git ./2305packages &
clone master https://github.com/immortalwrt/immortalwrt.git ./masterImmortalWrt &
clone master https://github.com/coolsnowwolf/lede.git ./lede &
#
# 新增软件包
clone master https://github.com/qwq233/UA4F.git ./package/ua4f &
clone main https://github.com/morytyann/OpenWrt-mihomo.git ./package/MihomoTProxy &
# cp -rf ./masterImmortalWrt/package/emortal/cpufreq ./package/emortal/
#
# 需要替换的包
clone dev https://github.com/vernesong/OpenClash.git ./package/luci-app-openclash &
# cp -rf ./2305packages/lang/ruby ./package/
# rm -rf ./package/utils/util-linux && cp -rf ./masterImmortalWrt/package/utils/util-linux ./package/utils/
wait

#* 预配置文件
cp -rf $opath/files ./
chmod +x ./files/etc/init.d/youhua
#
cp -rf $opath/seed/R2S/diffconfig ./.config
cp -rf $opath/seed/R2S/config-6.6 ./target/linux/rockchip/armv8/
#

#* Patchs
# 修复编译问题
cp -rf $opath/patch/attr/200-basename.patch ./feeds/packages/utils/attr/patches/
cp -rf $opath/patch/samba4/099-fix-librpc-missing-config-h.patch ./feeds/packages/net/samba4/patches/
#
patch -p1 <$opath/patch/qt6/qt6base_disable_lto.patch
#
patch -p1 <$opath/patch/libffi/libffi.patch
# openssl disable LTO
sed -i 's,no-mips16 gc-sections,no-mips16 gc-sections no-lto,g' package/libs/openssl/Makefile
# libsodium
sed -i 's,no-mips16,no-mips16 no-lto,g' feeds/packages/libs/libsodium/Makefile
#
# BBRv3
cp -rf $opath/patch/bbrv3/* ./
# 添加自定义 nft 规则页面
patch -p1 <$opath/patch/fw4/100-openwrt-firewall4-add-custom-nft-command-support.patch
#
pushd ./feeds/luci
patch -p1 <$opath/patch/fw4/04-luci-add-firewall4-nft-rules-file.patch
popd
#*获取更多patch
clone 24.10 https://github.com/QiuSimons/YAOF.git ./YAOF
# TCP optimizations
cp -rf ./YAOF/PATCH/kernel/6.7_Boost_For_Single_TCP_Flow/* ./target/linux/generic/backport-6.6/
cp -rf ./YAOF/PATCH/kernel/6.8_Boost_TCP_Performance_For_Many_Concurrent_Connections-bp_but_put_in_hack/* ./target/linux/generic/hack-6.6/
cp -rf ./YAOF/PATCH/kernel/6.8_Better_data_locality_in_networking_fast_paths-bp_but_put_in_hack/* ./target/linux/generic/hack-6.6/
# UDP optimizations
cp -rf ./YAOF/PATCH/kernel/6.7_FQ_packet_scheduling/* ./target/linux/generic/backport-6.6/
# arm64 型号名称
cp -rf ./YAOF/PATCH/kernel/arm/* ./target/linux/generic/hack-6.6/
# LRNG
cp -rf ./YAOF/PATCH/kernel/lrng/* ./target/linux/generic/hack-6.6/
echo '
# CONFIG_LRNG_AIS2031_NTG1_SEEDING_STRATEGY is not set
CONFIG_LRNG_APT_CUTOFF=325
CONFIG_LRNG_APT_CUTOFF_PERMANENT=371
CONFIG_LRNG_AUTO_SELECTED=y
CONFIG_LRNG_COMMON_DEV_IF=y
CONFIG_LRNG_CPU_ENTROPY_RATE=8
CONFIG_LRNG_CPU_FULL_ENT_MULTIPLIER=1
CONFIG_LRNG_DEV_IF=y
CONFIG_LRNG_DFLT_DRNG_CHACHA20=y
CONFIG_LRNG_DRNG_ATOMIC=y
CONFIG_LRNG_DRNG_CHACHA20=y
# CONFIG_LRNG_HWRAND_IF is not set
CONFIG_LRNG_JENT_ENTROPY_BLOCKS=128
# CONFIG_LRNG_JENT_ENTROPY_BLOCKS_DISABLED is not set
# CONFIG_LRNG_JENT_ENTROPY_BLOCKS_NO_1024 is not set
CONFIG_LRNG_JENT_ENTROPY_BLOCKS_NO_128=y
# CONFIG_LRNG_JENT_ENTROPY_BLOCKS_NO_256 is not set
# CONFIG_LRNG_JENT_ENTROPY_BLOCKS_NO_32 is not set
# CONFIG_LRNG_JENT_ENTROPY_BLOCKS_NO_512 is not set
# CONFIG_LRNG_JENT_ENTROPY_BLOCKS_NO_64 is not set
CONFIG_LRNG_JENT_ENTROPY_RATE=16
CONFIG_LRNG_KCAPI_IF=y
CONFIG_LRNG_RANDOM_IF=y
CONFIG_LRNG_RCT_CUTOFF=31
CONFIG_LRNG_RCT_CUTOFF_PERMANENT=81
CONFIG_LRNG_RUNTIME_ES_CONFIG=y
CONFIG_LRNG_SELFTEST=y
# CONFIG_LRNG_SELFTEST_PANIC is not set
CONFIG_LRNG_SHA256=y
# CONFIG_LRNG_SWITCH_DRNG is not set
# CONFIG_LRNG_SWITCH_HASH is not set
CONFIG_LRNG_SYSCTL=y
# CONFIG_LRNG_TESTING_MENU is not set
# CONFIG_RANDOM_DEFAULT_IMPL is not set
CONFIG_LRNG=y
# CONFIG_LRNG_IRQ is not set
CONFIG_LRNG_JENT=y
CONFIG_LRNG_CPU=y
# CONFIG_LRNG_SCHED is not set
# CONFIG_PHY_ROCKCHIP_SAMSUNG_HDPTX is not set
CONFIG_FRAME_WARN=2048
CONFIG_LEDS_TRIGGER_DISK=y
CONFIG_GCC11_NO_ARRAY_BOUNDS=y
CONFIG_GCC_ASM_GOTO_OUTPUT_WORKAROUND=y
# CONFIG_IIO_SCMI is not set
# CONFIG_CRYPTO_DEV_ROCKCHIP is not set
' >>./target/linux/generic/config-6.6
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# mount cgroupv2
pushd feeds/packages
patch -p1 <../../YAOF/PATCH/pkgs/cgroupfs-mount/0001-fix-cgroupfs-mount.patch
popd
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cp -rf ./YAOF/PATCH/pkgs/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ./YAOF/PATCH/pkgs/cgroupfs-mount/901-fix-cgroupfs-umount.patch ./feeds/packages/utils/cgroupfs-mount/patches/
cp -rf ./YAOF/PATCH/pkgs/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch ./feeds/packages/utils/cgroupfs-mount/patches/
#
# 使用专属优化
cp -rf ./YAOF/PATCH/kernel/rockchip/* ./target/linux/rockchip/patches-6.6/
patch -p1 <$opath/patch/target/target_r2s.patch
# patch -p1 <$opath/patch/squashfs/add_zstd_support.patch
cp -rf $opath/patch/target/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch ./target/linux/rockchip/patches-6.6/

#* 修改默认配置
#
#* 属性
# 修改默认ip
# sed -i 's/192.168.1.1/192.168.2.1/g' ./package/base-files/files/bin/config_generate
#
# 关闭缓解措施
# sed -i 's,rootwait,rootwait mitigations=off,g' ./target/linux/rockchip/image/default.bootscript
# 交换 LAN/WAN 口
# sed -i 's,"eth1" "eth0","eth0" "eth1",g' ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
# sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
#
#* 修改编译时配置
# 强制使用 O3 级别的优化
# sed -i 's/-Os/-O3/g' ./include/target.mk
