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
clone dev https://github.com/vernesong/OpenClash.git ./add/luci-app-openclash &
clone main https://github.com/morytyann/OpenWrt-mihomo.git ./add/MihomoTProxy &
clone main https://github.com/nikkinikki-org/OpenWrt-momo.git ./add/OpenWrt-momo &
clone dev https://github.com/stevenjoezhang/luci-app-adguardhome.git ./add/luci-app-adguardhome &
clone main https://github.com/sbwml/luci-app-openlist2.git ./add/luci-app-openlist2 &
clone js https://github.com/sirpdboy/luci-app-netspeedtest.git ./add/luci-app-netspeedtest &
clone js https://github.com/sirpdboy/luci-app-poweroffdevice.git ./add/luci-app-poweroffdevice &
clone master https://github.com/sundaqiang/openwrt-packages.git ./add/openwrt-packages &
clone master https://github.com/SunBK201/UA3F.git ./add/ua3f &
clone master https://github.com/QiuSimons/OpenWrt-Add.git ${WORKDIR}/OpenWrt-Add &
wait
popd
cp -rf ${WORKDIR}/OpenWrt-Add/addition-trans-zh ./package/add/



echo "更新 Feeds"
./scripts/feeds update -a 2>&1 | grep -iE "WARNING|ERROR"
./scripts/feeds install -a 2>&1 | grep -iE "WARNING|ERROR"
echo "强制覆盖"
./scripts/feeds install -f luci-app-openclash 2>&1 | grep -iE "WARNING|ERROR"

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
# 强制使用 O3 级别的优化
sed -i 's/-Os/-O3/g' ./include/target.mk
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
CONFIG_F2FS_FS_COMPRESSION=y
CONFIG_F2FS_FS_LZ4=y
CONFIG_F2FS_FS_LZ4HC=y
CONFIG_LZ4HC_COMPRESS=y
CONFIG_LZ4_COMPRESS=y
CONFIG_LZ4_DECOMPRESS=y
CONFIG_F2FS_FS_LZO=n
CONFIG_F2FS_FS_ZSTD=y
CONFIG_NET_DSA_KS8995=n
CONFIG_PKCS8_PRIVATE_KEY_PARSER=n
CONFIG_ZSTD_COMPRESS=y
CONFIG_BLK_CGROUP is not set
CONFIG_BPF_JIT_ALWAYS_ON=y
CONFIG_CGROUPS=y
CONFIG_CGROUP_BPF=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_DEBUG=n
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_HUGETLB=y
CONFIG_CGROUP_MISC=y
CONFIG_CGROUP_NET_CLASSID=n
CONFIG_CGROUP_NET_PRIO=n
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_RDMA=y
CONFIG_CGROUP_SCHED=y
CONFIG_CGROUP_WRITEBACK=y
CONFIG_CPUSETS=y
CONFIG_CPUSETS_V1=n
CONFIG_DEBUG_INFO_BTF=y
CONFIG_DEBUG_INFO_BTF_MODULES=y
CONFIG_EXT_GROUP_SCHED=y
CONFIG_FREEZER=y
CONFIG_GROUP_SCHED_WEIGHT=y
CONFIG_IKCONFIG=y
CONFIG_IKCONFIG_PROC=y
CONFIG_MEMCG=y
CONFIG_MEMCG_V1=n
CONFIG_MODULE_ALLOW_BTF_MISMATCH=n
CONFIG_NET_CLS_CGROUP=n
CONFIG_PAGE_COUNTER=y
CONFIG_PROC_PID_CPUSET=n
CONFIG_RT_GROUP_SCHED=n
CONFIG_SCHED_CLASS_EXT=y
CONFIG_SCHED_MM_CID=y
CONFIG_SLAB_OBJ_EXT=y
CONFIG_SOCK_CGROUP_DATA=y
# 以下可能不会出现在target
CONFIG_ZSTD_DECOMPRESS=y
CONFIG_FRAME_WARN=2048
CONFIG_SQUASHFS_FILE_DIRECT=y
CONFIG_SQUASHFS_FILE_CACHE=n
'
# 追加到指定的内核配置文件
echo "$CONFIG_CONTENT" | tee -a "./target/linux/rockchip/armv8/config-${linux_version}" "./target/linux/generic/config-${linux_version}" > /dev/null

echo "修复无法编译"
cp -f ${upstreampkg}/libs/libffi/Makefile ./package/feeds/packages/libffi/Makefile # node-ffi-napi 可能会出问题
patch -p0 < ${lynndir}/patch/uwsgi/Makefile.patch
patch -p0 < ${lynndir}/patch/btrfs-progs/Makefile.patch

echo "防止意外修改"
echo "
CONFIG_DOCKER_CGROUP_OPTIONS=n
CONFIG_PACKAGE_cgroupfs-mount=n
CONFIG_USE_LTO=y
" >> .config

echo "结束"