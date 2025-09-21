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
clone master https://github.com/QiuSimons/OpenWrt-Add.git ${workdir}/OpenWrt-Add &
wait
popd
cp -rf ${workdir}/OpenWrt-Add/addition-trans-zh ./package/add/

echo "缓存的工具链"
TOOLCHAIN_URL="https://github.com/sbwml/openwrt_caches/releases/download/openwrt-24.10/"
curl -L ${TOOLCHAIN_URL}/toolchain_musl_aarch64_cortex-a53_gcc-15.tar.zst -o toolchain.tar.zst --progress-bar
echo "Process Toolchain ..."
tar -I "zstd" -xf toolchain.tar.zst
rm -f toolchain.tar.zst
mkdir bin
find ./staging_dir/ -name '*' -exec touch {} \; >/dev/null 2>&1
find ./tmp/ -name '*' -exec touch {} \; >/dev/null 2>&1

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

echo "utils/cgroupfs-mount"
mkdir -p feeds/packages/utils/
cp -rf ${upstreampkg}/utils/cgroupfs-mount ./feeds/packages/utils/

# 功能增强Patch
echo "BBRv3"
cp -rf ${lynndir}/patch/bbrv3/linux/* ./target/linux/generic/hack-${linux_version}/
cp -rf ${lynndir}/patch/bbrv3/iproute2/* ./package/network/utils/iproute2/patches/
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf

# Patch LuCI 以支持自定义 nft 规则 # sbwml 已进行
# echo "FW4"
# patch -p1 < ${lynndir}/patch/fw4/100-openwrt-firewall4-add-custom-nft-command-support.patch
# cp -f ${lynndir}/patch/fw4/100-fw4-add-custom-nft-command-support.patch ./package/network/config/firewall4/patches/
# pushd feeds/luci
# patch -p1 <${lynndir}/patch/fw4/0004-luci-add-firewall-add-custom-nft-rule-support.patch
# popd

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
echo "交换 LAN/WAN 口"
sed -i 's,"eth1" "eth0","eth0" "eth1",g' ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" ./target/linux/rockchip/armv8/base-files/etc/board.d/02_network

echo "强制使用 O3 级别的优化、使用专属优化"
patch -p1 < ${lynndir}/patch/include/target.mk.patch


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


echo "以下来源于 sbwml"

echo "通用补丁"
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0001-tools-add-upx-tools.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0002-rootfs-add-upx-compression-support.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0003-rootfs-add-r-w-permissions-for-UCI-configuration-fil.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0004-rootfs-Add-support-for-local-kmod-installation-sourc.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0005-kernel-Add-support-for-llvm-clang-compiler.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0006-build-kernel-add-out-of-tree-kernel-config.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0007-include-kernel-add-miss-config-for-linux-6.11.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0008-meson-add-platform-variable-to-cross-compilation-fil.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0009-kernel-add-legacy-cgroup-v1-memory-controller.patch
patch -p1 < ${sbwml}/openwrt/patch/generic-24.10/0010-kernel-add-PREEMPT_RT-support-for-aarch64-x86_64.patch

echo "attr no-mold"
sed -i '/PKG_BUILD_PARALLEL/aPKG_BUILD_FLAGS:=no-mold' feeds/packages/utils/attr/Makefile

echo "Use nginx instead of uhttpd"
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd-mod-ubus //' feeds/luci/collections/luci/Makefile
sed -i 's/+uhttpd /+luci-nginx /g' feeds/luci/collections/luci-light/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl-openssl/Makefile
sed -i "s/+luci /+luci-nginx /g" feeds/luci/collections/luci-ssl/Makefile
sed -i 's/+uhttpd +uhttpd-mod-ubus /+luci-nginx /g' feeds/packages/net/wg-installer/Makefile
sed -i '/uhttpd-mod-ubus/d' feeds/luci/collections/luci-light/Makefile
sed -i 's/+luci-nginx \\$/+luci-nginx/' feeds/luci/collections/luci-light/Makefile

echo "libubox"
sed -i '/TARGET_CFLAGS/ s/$/ -Os/' package/libs/libubox/Makefile

echo "DPDK & NUMACTL"
mkdir -p package/new
cp -rf ${sbwml}/openwrt/patch/dpdk/dpdk package/new/
cp -rf ${sbwml}/openwrt/patch/dpdk/numactl package/new/

echo "Shortcut Forwarding Engine"
cp -rf ${ext}/shortcut-fe package/new/

echo "Patch FireWall 4"
# sed -i 's|$(PROJECT_GIT)/project|https://github.com/openwrt|g' package/network/config/firewall4/Makefile
mkdir -p package/network/config/firewall4/patches
echo "fix ct status dnat"
cp -rf ${sbwml}/openwrt/patch/firewall4/firewall4_patches/990-unconditionally-allow-ct-status-dnat.patch package/network/config/firewall4/patches/
echo "fullcone"
cp -rf ${sbwml}/openwrt/patch/firewall4/firewall4_patches/999-01-firewall4-add-fullcone-support.patch package/network/config/firewall4/patches/
echo "bcm fullcone"
cp -rf ${sbwml}/openwrt/patch/firewall4/firewall4_patches/999-02-firewall4-add-bcm-fullconenat-support.patch package/network/config/firewall4/patches/
echo "kernel version"
cp -rf ${sbwml}/openwrt/patch/firewall4/firewall4_patches/002-fix-fw4.uc-adept-kernel-version-type-of-x.x.patch package/network/config/firewall4/patches/
echo "fix flow offload"
cp -rf ${sbwml}/openwrt/patch/firewall4/firewall4_patches/001-fix-fw4-flow-offload.patch package/network/config/firewall4/patches/
echo "add custom nft command support"
patch -p1 < ${sbwml}/openwrt/patch/firewall4/100-openwrt-firewall4-add-custom-nft-command-support.patch
echo "libnftnl"
mkdir -p package/libs/libnftnl/patches
cp -rf ${sbwml}/openwrt/patch/firewall4/libnftnl/0001-libnftnl-add-fullcone-expression-support.patch package/libs/libnftnl/patches/
cp -rf ${sbwml}/openwrt/patch/firewall4/libnftnl/0002-libnftnl-add-brcm-fullcone-support.patch package/libs/libnftnl/patches/
echo "nftables"
mkdir -p package/network/utils/nftables/patches
cp -rf ${sbwml}/openwrt/patch/firewall4/nftables/0001-nftables-add-fullcone-expression-support.patch package/network/utils/nftables/patches/
cp -rf ${sbwml}/openwrt/patch/firewall4/nftables/0002-nftables-add-brcm-fullconenat-support.patch package/network/utils/nftables/patches/
cp -rf ${sbwml}/openwrt/patch/firewall4/nftables/0003-drop-rej-file.patch package/network/utils/nftables/patches/

echo "natflow"
clone main https://github.com/sbwml/package_new_natflow package/new/natflow

echo "Patch Luci add nft_fullcone/bcm_fullcone & shortcut-fe & natflow & ipv6-nat & custom nft command option"
pushd feeds/luci
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0002-luci-app-firewall-add-shortcut-fe-option.patch
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0003-luci-app-firewall-add-ipv6-nat-option.patch
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0004-luci-add-firewall-add-custom-nft-rule-support.patch
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0005-luci-app-firewall-add-natflow-offload-support.patch
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0006-luci-app-firewall-enable-hardware-offload-only-on-de.patch
    patch -p1 < ${sbwml}/openwrt/patch/firewall4/luci-24.10/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch
popd

echo "cgroupfs-mount"
echo "fix unmount hierarchical mount"
pushd feeds/packages
    cat ${sbwml}/openwrt/patch/cgroupfs-mount/0001-fix-cgroupfs-mount.patch | patch -p1
popd
echo "mount cgroup v2 hierarchy to /sys/fs/cgroup/cgroup2"
mkdir -p feeds/packages/utils/cgroupfs-mount/patches
cat ${sbwml}/openwrt/patch/cgroupfs-mount/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch > feeds/packages/utils/cgroupfs-mount/patches/900-mount-cgroup-v2-hierarchy-to-sys-fs-cgroup-cgroup2.patch
cat ${sbwml}/openwrt/patch/cgroupfs-mount/901-fix-cgroupfs-umount.patch > feeds/packages/utils/cgroupfs-mount/patches/901-fix-cgroupfs-umount.patch
echo "docker systemd support"
cat ${sbwml}/openwrt/patch/cgroupfs-mount/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch > feeds/packages/utils/cgroupfs-mount/patches/902-mount-sys-fs-cgroup-systemd-for-docker-systemd-suppo.patch

echo "nginx - ubus"
sed -i 's/ubus_parallel_req 2/ubus_parallel_req 6/g' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 300;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
echo "nginx - config"
cat ${sbwml}/openwrt/nginx/luci.locations > feeds/packages/net/nginx/files-luci-support/luci.locations
cat ${sbwml}/openwrt/nginx/uci.conf.template > feeds/packages/net/nginx-util/files/uci.conf.template
echo "uwsgi - fix timeout"
sed -i '$a cgi-timeout = 600' feeds/packages/net/uwsgi/files-luci-support/luci-*.ini
sed -i '/limit-as/c\limit-as = 5000' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
echo "uwsgi - performance"
sed -i 's/threads = 1/threads = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/processes = 3/processes = 4/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
sed -i 's/cheaper = 1/cheaper = 2/g' feeds/packages/net/uwsgi/files-luci-support/luci-webui.ini
echo "rpcd - fix timeout"
sed -i 's/option timeout 30/option timeout 60/g' package/system/rpcd/files/rpcd.config
sed -i 's#20) \* 1000#60) \* 1000#g' feeds/luci/modules/luci-base/htdocs/luci-static/resources/rpc.js

echo "luci-mod extra"
pushd feeds/luci
    cat ${sbwml}/openwrt/patch/luci/0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch | patch -p1
    cat ${sbwml}/openwrt/patch/luci/0002-luci-mod-status-displays-actual-process-memory-usage.patch | patch -p1
    cat ${sbwml}/openwrt/patch/luci/0003-luci-mod-status-storage-index-applicable-only-to-val.patch | patch -p1
    cat ${sbwml}/openwrt/patch/luci/0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch | patch -p1
    cat ${sbwml}/openwrt/patch/luci/0005-luci-mod-system-add-refresh-interval-setting.patch | patch -p1
    cat ${sbwml}/openwrt/patch/luci/0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch | patch -p1
    cat ${sbwml}/openwrt/patch/luci/0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch | patch -p1
popd

echo "Luci diagnostics.js"
sed -i "s/openwrt.org/www.qq.com/g" feeds/luci/modules/luci-mod-network/htdocs/luci-static/resources/view/network/diagnostics.js

echo "rootfs files"
mkdir -p files/etc/sysctl.d
cp -rf ${sbwml}/openwrt/files/etc/sysctl.d/10-default.conf files/etc/sysctl.d/10-default.conf
cp -rf ${sbwml}/openwrt/files/etc/sysctl.d/15-vm-swappiness.conf files/etc/sysctl.d/15-vm-swappiness.conf
cp -rf ${sbwml}/openwrt/files/etc/sysctl.d/16-udp-buffer-size.conf files/etc/sysctl.d/16-udp-buffer-size.conf

echo "NTP"
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

echo "LRNG"
pushd target/linux/generic/hack-6.12
    cp -rf ${sbwml}/openwrt/patch/kernel-6.12/lrng/* ./
popd

echo "wireless-regdb"
cat ${sbwml}/openwrt/patch/openwrt-6.x/500-world-regd-5GHz.patch > package/firmware/wireless-regdb/patches/500-world-regd-5GHz.patch

echo "kernel patch"
echo "btf: silence btf module warning messages"
cat ${sbwml}/openwrt/patch/kernel-6.12/btf/990-btf-silence-btf-module-warning-messages.patch > target/linux/generic/hack-6.12/990-btf-silence-btf-module-warning-messages.patch
echo "cpu model"
cat ${sbwml}/openwrt/patch/kernel-6.12/arm64/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch > target/linux/generic/hack-6.12/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
echo "fullcone"
cat ${sbwml}/openwrt/patch/kernel-6.12/net/952-net-conntrack-events-support-multiple-registrant.patch > target/linux/generic/hack-6.12/952-net-conntrack-events-support-multiple-registrant.patch
echo "bcm-fullcone"
cat ${sbwml}/openwrt/patch/kernel-6.12/net/982-add-bcm-fullcone-support.patch > target/linux/generic/hack-6.12/982-add-bcm-fullcone-support.patch
cat ${sbwml}/openwrt/patch/kernel-6.12/net/983-add-bcm-fullcone-nft_masq-support.patch > target/linux/generic/hack-6.12/983-add-bcm-fullcone-nft_masq-support.patch
echo "shortcut-fe"
cat ${sbwml}/openwrt/patch/kernel-6.12/net/601-netfilter-export-udp_get_timeouts-function.patch > target/linux/generic/hack-6.12/601-netfilter-export-udp_get_timeouts-function.patch
cat ${sbwml}/openwrt/patch/kernel-6.12/net/953-net-patch-linux-kernel-to-support-shortcut-fe.patch > target/linux/generic/hack-6.12/953-net-patch-linux-kernel-to-support-shortcut-fe.patch


echo "使用clang编译内核，开启LTO"
echo '
# Kernel - CLANG LTO
CONFIG_KERNEL_CC="ccache clang"
CONFIG_EXTRA_OPTIMIZATION=""
CONFIG_PACKAGE_kselftests-bpf=n
' >> .config

echo "
# Kernel - LRNG
CONFIG_KERNEL_LRNG=y
CONFIG_PACKAGE_urandom-seed=n
CONFIG_PACKAGE_urngd=n
" >> .config

echo "
CONFIG_PACKAGE_dpdk-tools=y
CONFIG_PACKAGE_numactl=y
" >> .config

echo "结束"