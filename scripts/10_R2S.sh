echo "权限状态："
ls -l
id

# echo "自定义feed源"
echo "src-link add ./package/add/" >> "feeds.conf.default"

echo "覆盖或添加包"
clone dev https://github.com/vernesong/OpenClash.git ./package/add/luci-app-openclash &
clone master https://github.com/qwq233/UA4F.git ./package/add/ua4f &
clone main https://github.com/morytyann/OpenWrt-mihomo.git ./package/add/MihomoTProxy &
wait

echo "更新 Feeds"
./scripts/feeds update -a 2>&1 | grep -i "WARNING"
./scripts/feeds install -a 2>&1 | grep -i "WARNING"

echo "下载其他仓库"
# clone openwrt-23.05 https://github.com/immortalwrt/packages.git ./2305packages &
# clone master https://github.com/immortalwrt/immortalwrt.git ./masterImmortalWrt &
# clone 24.10 https://github.com/QiuSimons/YAOF.git ./YAOF &
# clone master https://github.com/coolsnowwolf/lede.git ../lede &
# clone master https://github.com/lisaac/luci-app-dockerman ../dockerman &
# clone master https://github.com/lisaac/luci-lib-docker ../docker_lib &
# wait # 等待后台全部完成



# 功能增强Patch
echo "BBRv3"
cp -rf ${lynndir}/patch/bbrv3/linux/* ./target/linux/generic/hack-${linux_version}/
cp -rf ${lynndir}/patch/bbrv3/iproute2/* ./package/network/utils/iproute2/patches/
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf

# Patch LuCI 以支持自定义 nft 规则
echo "FW4"
patch -p1 < ${lynndir}/patch/fw4/100-openwrt-firewall4-add-custom-nft-command-support.patch
cp -f ${lynndir}/patch/fw4/100-fw4-add-custom-nft-command-support.patch ./package/network/config/firewall4/patches/
pushd feeds/luci
patch -p1 <${lynndir}/patch/fw4/luci/0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd

# 超频补丁
echo "超频"
cp -f ${lynndir}/patch/target/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch ./target/linux/rockchip/armv8/patches-${linux_version}/

#Vermagic # 内核模块兼容
echo "Vermagic"
# wget https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/targets/rockchip/armv8/profiles.json
wget https://downloads.immortalwrt.org/snapshots/targets/rockchip/armv8/profiles.json
jq -r '.linux_kernel.vermagic' profiles.json >.vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk



# 自定义 Patch
echo "SquashFS 支持 Zstd 和 LZ4"
patch -p1 <${lynndir}/patch/squashfs/squashfs4_add_zstd_lz4_support.patch
CONFIG_CONTENT='
CONFIG_SQUASHFS_XZ=n
CONFIG_SQUASHFS_ZSTD=y
CONFIG_ZSTD_DECOMPRESS=y
'
# 查找所有与内核相关的配置文件并将这些配置项追加到文件末尾
find ./target/linux/ -name "config-${linux_version}" | xargs -I{} sh -c "echo '$CONFIG_CONTENT' | tee -a {} > /dev/null"


echo "修改源码"
# 强制使用 O2 级别的优化
sed -i 's/-Os/-O2/g' ./include/target.mk
# 交换 LAN/WAN 口
sed -i 's,"eth1" "eth0","eth0" "eth1",g' ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
# 使用专属优化
sed -i 's,CPU_TYPE ?= generic,CPU_TYPE ?= cortex-a53,g' include/target.mk
sed -i 's,-mcpu=generic,-march=armv8-a+crypto+crc -mtune=cortex-a53,g' include/target.mk
sed -i 's,-mcpu=cortex-a53,-march=armv8-a+crypto+crc -mtune=cortex-a53,g' include/target.mk


# echo "清理未使用的文件"
# rm -rf ./2305packages
# rm -rf ./masterimmortalwrt
# rm -rf ./YAOF
# rm -rf ../lede
# rm -rf ../dockerman
# rm -rf ../docker_lib

# echo "移除问题软件包"
# 缺少依赖的包
# uneedpkg="$uneedpkg luci-app-qbittorrent qBittorrent-Enhanced-Edition bcm27xx-eeprom boost efibootmgr freeswitch mc micropython-lib owut python-gmpy2 pdns mpd netwhere libtorrent-rasterbar kea i2pd hyperscan freetdm domoticz dnsdist pdns-recursor schroot trojan trojan-plus luci-app-passwall libmpc freeswitch-mod-bcg729 snort3 openappid"
# ./scripts/feeds uninstall -f $uneedpkg 2>&1 | grep -i "WARNING"
