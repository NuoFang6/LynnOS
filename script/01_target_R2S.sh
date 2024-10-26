#!/bin/bash
#* 脚本将在 immortalWrt 目录下运行
# /home/runner/work/LynnOS/immortalWrt
opath="/home/runner/work/LynnOS/LynnOS"

#* 自定义feed源
cp -rf $opath/script/feeds.conf.default ./feeds.conf.default

#* 更新 Feeds
./scripts/feeds update -a >/dev/null
./scripts/feeds install -a >/dev/null

#* 移除无用软件包
uneedpkg="luci-app-appfilter luci-app-openclash"
./scripts/feeds uninstall $uneedpkg >/dev/null

#* 获取额外的软件包
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash.git ./package/luci-app-openclash >/dev/null
git clone -b master --depth 1 https://github.com/qwq233/UA4F.git ./package/ua4f >/dev/null

#* 滚回无法编译的包
# mkdir -p ./2305packages/
# git clone -b openwrt-23.05 --depth 1 https://github.com/immortalwrt/packages.git ./2305packages >/dev/null

#* 预配置文件
cp -rf $opath/files ./
chmod +x ./files/etc/init.d/youhua
#
cp -rf $opath/seed/R2S/.config ./
#
# CONFIG_GCC10_NO_ARRAY_BOUNDS=y
# # CONFIG_ARM_CORESIGHT_PMU_ARCH_SYSTEM_PMU is not set
# # CONFIG_ARM_SMMU_V3_PMU is not set
# CONFIG_GCC11_NO_ARRAY_BOUNDS=y
# CONFIG_GCC_ASM_GOTO_OUTPUT_WORKAROUND=y
# # CONFIG_IIO_SCMI is not set
# CONFIG_RANDOMIZE_BASE=y
# CONFIG_RANDOMIZE_MODULE_REGION_FULL=y
# # CONFIG_MPTCP_IPV6 is not set
# # CONFIG_CRYPTO_DEV_ROCKCHIP is not set
# CONFIG_ARM_ROCKCHIP_CPUFREQ=y

#* Patchs
# 修复编译问题
cp -rf $opath/patch/attr/200-basename.patch ./feeds/packages/utils/attr/patches/
pushd ./feeds/packages/libs/qt6base
patch -p0 <$opath/patch/qt6/qt6base_disable_lto.patch
popd
# 添加自定义 nft 规则页面
patch -p1 <$opath/patch/fw4/100-openwrt-firewall4-add-custom-nft-command-support.patch
pushd ./feeds/luci
patch -p1 <$opath/patch/fw4/04-luci-add-firewall4-nft-rules-file.patch
popd
#
# 使用专属优化
patch -p1 <$opath/patch/target/target_r2s.patch

#* 修改默认配置
#
#* 属性
# 修改默认ip
sed -i 's/192.168.1.1/192.168.2.1/g' ./package/base-files/files/bin/config_generate
# 修改默认主机名
sed -i 's/ImmortalWrt/LynnOS/g' ./package/base-files/files/bin/config_generate
#
# 关闭缓解措施
sed -i 's,rootwait,rootwait mitigations=off rootfs_mount_options.threads=4,g' ./target/linux/rockchip/image/default.bootscript
# 交换 LAN/WAN 口
sed -i 's,"eth1" "eth0","eth0" "eth1",g' ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
#
#* 修改编译时配置
# 强制使用 O3 级别的优化
sed -i 's/-Os/-O3/g' ./include/target.mk
