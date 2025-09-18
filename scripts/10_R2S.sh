clone() {
  # 参数1: 分支名  参数2: 仓库地址  参数3: 目标目录
  if [ $# -lt 3 ]; then
    echo "用法: clone <branch> <repo_url> <target_dir>" >&2
    return 1
  fi
  local branch_name="$1" repo_url="$2" target_dir="$3"
  git clone -q -b "$branch_name" --depth 1 --single-branch --no-tags "$repo_url" "$target_dir"
}


echo "权限状态："
ls -l
id

# echo "自定义feed源"
echo "src-link new ./package/new/" >> "feeds.conf.default"
# echo "src-link add ./package/add/" >> "feeds.conf.default"

echo "覆盖或添加包"
pushd package
# clone master https://github.com/QiuSimons/OpenWrt-Add.git ./new &
clone dev https://github.com/vernesong/OpenClash.git ./add/luci-app-openclash &
clone master https://github.com/qwq233/UA4F.git ./add/ua4f &
clone main https://github.com/morytyann/OpenWrt-mihomo.git ./add/MihomoTProxy &
clone dev https://github.com/stevenjoezhang/luci-app-adguardhome.git ./add/luci-app-adguardhome &
clone main https://github.com/sbwml/luci-app-openlist2.git ./add/luci-app-openlist2 &
clone js https://github.com/sirpdboy/luci-app-netspeedtest.git ./add/luci-app-netspeedtest &
clone js https://github.com/sirpdboy/luci-app-poweroffdevice.git ./add/luci-app-poweroffdevice &
clone master https://github.com/sundaqiang/openwrt-packages.git ./add/openwrt-packages &
clone master https://github.com/SunBK201/UA3F.git ./add/ua3f &
wait
popd

echo "更新 Feeds"
./scripts/feeds update -a 2>&1 | grep -i "WARNING"
./scripts/feeds install -a 2>&1 | grep -i "WARNING"
echo "强制覆盖"
./scripts/feeds install -f luci-app-openclash 2>&1 | grep -i "WARNING"

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
patch -p1 <${lynndir}/patch/fw4/0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd

# 超频补丁
echo "超频"
cp -f ${lynndir}/patch/target/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch ./target/linux/rockchip/patches-${linux_version}

#Vermagic # 内核模块兼容
echo "Vermagic"
# wget https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/targets/rockchip/armv8/profiles.json
wget https://downloads.immortalwrt.org/snapshots/targets/rockchip/armv8/profiles.json
jq -r '.linux_kernel.vermagic' profiles.json >.vermagic
cat .vermagic
sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk



# 自定义 Patch
echo "SquashFS 支持 Zstd 和 LZ4"
patch -p1 <${lynndir}/patch/squashfs/squashfs4_add_zstd_lz4_support.patch

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


echo "应用配置"
cp -f ${lynndir}/seed/R2S/seed.config .config
echo "去除不必要的过滤"
sed -i 's/^CONFIG_FRAME_WARN=.*/# &/' ./target/linux/generic/config-filter
echo "应用内核配置"
CONFIG_CONTENT='
CONFIG_ASN1=y
CONFIG_ASSOCIATIVE_ARRAY=y
CONFIG_ASYMMETRIC_KEY_TYPE=y
CONFIG_ASYMMETRIC_PUBLIC_KEY_SUBTYPE=y
CONFIG_CLZ_TAB=y
CONFIG_CPU_FREQ_GOV_CONSERVATIVE=y
CONFIG_CPU_FREQ_GOV_USERSPACE=y
CONFIG_CPU_IDLE_GOV_MENU=n
CONFIG_CPU_IDLE_GOV_TEO=y
CONFIG_CRYPTO_AES_ARM64_NEON_BLK=y
CONFIG_CRYPTO_CBC=y
CONFIG_CRYPTO_CURVE25519=y
CONFIG_CRYPTO_DES=y
CONFIG_CRYPTO_DEV_ROCKCHIP=y
CONFIG_CRYPTO_DEV_ROCKCHIP_DEBUG=y
CONFIG_CRYPTO_DH=y
CONFIG_CRYPTO_DH_RFC7919_GROUPS=n
CONFIG_CRYPTO_ECC=y
CONFIG_CRYPTO_ECDH=y
CONFIG_CRYPTO_ECDSA=y
CONFIG_CRYPTO_ECRDSA=y
CONFIG_CRYPTO_ENGINE=y
CONFIG_CRYPTO_HASH_INFO=y
CONFIG_CRYPTO_HW=y
CONFIG_CRYPTO_LIB_CURVE25519_GENERIC=y
CONFIG_CRYPTO_LIB_CURVE25519_INTERNAL=y
CONFIG_CRYPTO_LIB_DES=y
CONFIG_CRYPTO_LIB_POLY1305_GENERIC=y
CONFIG_CRYPTO_MD5=y
CONFIG_CRYPTO_NHPOLY1305=y
CONFIG_CRYPTO_NHPOLY1305_NEON=y
CONFIG_CRYPTO_RNG_DEFAULT=y
CONFIG_CRYPTO_RSA=y
CONFIG_CRYPTO_SHA1=y
CONFIG_CRYPTO_SHA1_ARM64_CE=y
CONFIG_CRYPTO_SHA256_ARM64=y
CONFIG_CRYPTO_SHA2_ARM64_CE=y
CONFIG_CRYPTO_SHA512_ARM64=y
CONFIG_CRYPTO_SHA512_ARM64_CE=y
CONFIG_CRYPTO_SIG=y
CONFIG_CRYPTO_SIG2=y
CONFIG_CRYPTO_STREEBOG=y
CONFIG_DEFAULT_BBR=y
CONFIG_DEFAULT_CUBIC=n
CONFIG_DEFAULT_TCP_CONG="bbr"
CONFIG_KEYS=y
CONFIG_MPILIB=y
CONFIG_MTK_NET_PHYLIB=y
CONFIG_OID_REGISTRY=y
CONFIG_PKCS8_PRIVATE_KEY_PARSER=n
CONFIG_SQUASHFS_XZ=n
CONFIG_SQUASHFS_ZSTD=y
CONFIG_TCP_CONG_BBR=y
CONFIG_TOOLS_SUPPORT_RELR=y
CONFIG_ZSTD_COMMON=y
# 以下可能不会出现在target
CONFIG_ZSTD_DECOMPRESS=y
CONFIG_FRAME_WARN=2048
'
# 追加到指定的内核配置文件
echo "$CONFIG_CONTENT" | tee -a "./target/linux/rockchip/armv8/config-${linux_version}" "./target/linux/generic/config-${linux_version}" > /dev/null

echo "修复无法编译"
cp -f ${upstreampkg}/libs/libffi/Makefile ./package/feeds/packages/libffi/Makefile # node-ffi-napi 可能会出问题
patch -p0 < ${lynndir}/patch/uwsgi/Makefile.patch
patch -p0 < ${lynndir}/patch/ua4f/Makefile.patch
patch -p0 < ${lynndir}/patch/btrfs-progs/Makefile.patch
patch -p0 < ${lynndir}/patch/include/download.mk.patch

echo "修改 r8152 驱动为最新"
sed -i \
  -e 's/^PKG_VERSION:=.*/PKG_VERSION:=main-latest/' \
  -e '/^PKG_SOURCE:=/c\
PKG_SOURCE_PROTO:=git\
PKG_SOURCE_URL:=https://github.com/wget/realtek-r8152-linux.git\
PKG_SOURCE_VERSION:=master\
PKG_MIRROR_HASH:=skip' \
  -e '/^PKG_SOURCE_URL:=@IMMORTALWRT/d' \
  -e '/^PKG_HASH:=/d' \
  ./package/kernel/r8152/Makefile

echo "结束"