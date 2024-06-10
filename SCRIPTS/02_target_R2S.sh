#!/bin/bash
clear

# 使用专属优化
patch -p1 <../PATCH/target/target_r2s.patch
patch -p1 <../PATCH/squashfs/add_zstd_support.patch

# 关闭缓解措施
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript

# 交换 LAN/WAN 口
sed -i 's,"eth1" "eth0","eth0" "eth1",g' target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" target/linux/rockchip/armv8/base-files/etc/board.d/02_network

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
EOL
cp -rf ../SEED/R2S/config-6.6 target/linux/rockchip/armv8/config-6.6
chmod -R 755 ./

find ./ -name *.orig | xargs rm -f &
find ./ -name *.rej | xargs rm -f

wait
