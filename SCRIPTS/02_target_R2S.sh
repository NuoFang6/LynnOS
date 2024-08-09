#!/bin/bash

# 预配置文件
cp -rf ../PATCH/files ./

chmod +x files/etc/init.d/youhua

# 非源码 ipk
# UA3F
mkdir -p ../PATCH/files/etc/pre_install/
wget -q -O ../PATCH/files/etc/pre_install/ua3f_armv8.ipk $(curl -s https://api.github.com/repos/SunBK201/UA3F/releases/latest | grep browser_download_url | grep armv8.ipk | cut -d '"' -f 4) &

# 使用 O3 级别的优化
sed -i 's/-Os/-O3/g' ./include/target.mk
# 使用专属优化
patch -p1 <../PATCH/target/target_r2s.patch
patch -p1 <../PATCH/squashfs/add_zstd_support.patch

# 关闭缓解措施
sed -i 's,rootwait,rootwait mitigations=off rootfs_mount_options.threads=4,g' target/linux/rockchip/image/default.bootscript

# 交换 LAN/WAN 口
sed -i 's,"eth1" "eth0","eth0" "eth1",g' target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" target/linux/rockchip/armv8/base-files/etc/board.d/02_network

# 默认开启 Irqbalance
# sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

# Clash 内核
# mkdir -p files/etc/openclash/core

# TODO
# 预配置文件
cp -rf ../SEED/R2S/config.seed .config

sed -i '/CONFIG_GCC10_NO_ARRAY_BOUNDS=y/d' ../SEED/R2S/config-6.6
cat <<EOL >>../SEED/R2S/config-6.6
# CONFIG_ARM_CORESIGHT_PMU_ARCH_SYSTEM_PMU is not set
# CONFIG_ARM_SMMU_V3_PMU is not set
CONFIG_GCC11_NO_ARRAY_BOUNDS=y
CONFIG_GCC_ASM_GOTO_OUTPUT_WORKAROUND=y
# CONFIG_IIO_SCMI is not set
CONFIG_RANDOMIZE_BASE=y
CONFIG_RANDOMIZE_MODULE_REGION_FULL=y
# CONFIG_MPTCP_IPV6 is not set
# CONFIG_CRYPTO_DEV_ROCKCHIP is not set
CONFIG_ARM_ROCKCHIP_CPUFREQ=y
EOL
cp -rf ../SEED/R2S/config-6.6 target/linux/rockchip/armv8/config-6.6
chmod -R 755 ./

find ./ -name *.orig | xargs rm -f &
find ./ -name *.rej | xargs rm -f

wait
