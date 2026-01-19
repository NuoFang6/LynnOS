# 注意：此脚本在容器内运行
#
# p: 打印日志
# clone: git浅克隆，参数1: 分支名 参数2: 仓库地址 参数3: 目标目录
# set_env: 设置环境变量，参数1: 变量名 参数2: 变量值
#
# 运行到这个脚本时依赖已安装；${workdir} 和 ${lynndir} 已设置
#

p "配置 git"
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global core.abbrev auto




p "修改时区为上海"
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime



p "克隆 immortalwrt 到 ${workdir}/immortalwrt"
. set_env "wrtdir" "${workdir}/immortalwrt"
umask 0022
if [ ${immortalwrt_branch} == "MTK2410" ]; then
    p "使用MTK优化分支"
    clone "openwrt-24.10-6.6" https://github.com/padavanonly/immortalwrt-mt798x-6.6.git ${wrtdir}
else
    p "使用 immortalwrt ${immortalwrt_branch}"
    clone ${immortalwrt_branch} https://github.com/immortalwrt/immortalwrt ${wrtdir}
fi
pushd ${wrtdir}
git config core.filemode false # 忽略权限变更
popd





p ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

p "进入编译目录 ${wrtdir}"
cd ${wrtdir}


p "获取内核版本"
current_version=$(sed -n 's/^KERNEL_PATCHVER:=//p' ./target/linux/mediatek/Makefile)
. set_env "linux_version" "${current_version}"



p "覆盖或添加包"
pushd package
clone dev https://github.com/vernesong/OpenClash.git ./add/luci-app-openclash &
clone main https://github.com/morytyann/OpenWrt-mihomo.git ./add/MihomoTProxy &
clone main https://github.com/nikkinikki-org/OpenWrt-momo.git ./add/OpenWrt-momo &
clone dev https://github.com/stevenjoezhang/luci-app-adguardhome.git ./add/luci-app-adguardhome &
clone main https://github.com/sbwml/luci-app-openlist2.git ./add/luci-app-openlist2 &
clone master https://github.com/sirpdboy/luci-app-netspeedtest.git ./add/luci-app-netspeedtest &
clone master https://github.com/sirpdboy/luci-app-poweroffdevice.git ./add/luci-app-poweroffdevice &
clone master https://github.com/SunBK201/UA3F.git ./add/ua3f &
clone main https://github.com/EasyTier/luci-app-easytier.git ./add/luci-app-easytier &
clone main https://github.com/sbwml/package_kernel_tcp-brutal ./add/tcp-brutal &
wait && sync
popd
sed -i "1isrc-link add ${wrtdir}/package/add" feeds.conf.default # 这里一定要用绝对路径；将包含自定义订阅源的行移动到标准订阅源上方，即可覆盖标准订阅源
# -i: 表示直接修改文件（in-place）。
# 1i: 表示在第 1 行之前插入（insert）。

p "下载其他仓库"
# clone master https://github.com/sundaqiang/openwrt-packages.git ./add/openwrt-packages &
# p "克隆 openwrt packages"
# . set_env "upstream_packages" "${workdir}/upstream/packages"
# clone openwrt-25.12 https://github.com/openwrt/packages.git ${upstream_packages} & # TODO: 自动检测稳定版分支名
# clone openwrt-23.05 https://github.com/immortalwrt/packages.git ./2305packages &
# clone master https://github.com/immortalwrt/immortalwrt.git ./masterImmortalWrt &
# clone 24.10 https://github.com/QiuSimons/YAOF.git ./YAOF &
# clone master https://github.com/coolsnowwolf/lede.git ../lede &
# clone master https://github.com/lisaac/luci-app-dockerman ../dockerman &
# clone master https://github.com/lisaac/luci-lib-docker ../docker_lib &
wait && sync


p "更新 Feeds"
./scripts/feeds update -f -a
./scripts/feeds install -f -a # TODO

p "修复编译问题"
p "卸载 qBittorrent-Enhanced-Edition"
./scripts/feeds uninstall luci-app-qbittorrent qBittorrent-Enhanced-Edition || true
p "卸载无法下载的包"
./scripts/feeds uninstall aic8800 || true
p "卸载无法编译的包"
./scripts/feeds uninstall luci-app-advanced-reboot onionshare-cli exim luci-app-radicale python-zope-event python-zope-interface python-gevent python-twisted || true
p "修复 elfutils"
patch -p1 < ${lynndir}/patch/elfutils/fix-elfutils-gcc15.patch || true




p "应用自定义修改"
if [ ${current_version} == "6.6" ]; then
clone "24.10" https://github.com/QiuSimons/YAOF.git ./YAOF
p "BBRv3"
    cp -rf ./YAOF/PATCH/kernel/bbr3/* ./target/linux/generic/hack-${linux_version}/
p "复制 lrng 补丁"
    cp -rf ${lynndir}/patch/lrng/v60/* ./target/linux/generic/hack-${linux_version}/
    cp -rf ${lynndir}/patch/lrng/6.6/* ./target/linux/generic/hack-${linux_version}/
p "其它补丁"
    cp -rf ./YAOF/PATCH/kernel/6.7_Boost_For_Single_TCP_Flow/* ./target/linux/generic/hack-${linux_version}/
    cp -rf ./YAOF/PATCH/kernel/6.7_FQ_packet_scheduling/* ./target/linux/generic/hack-${linux_version}/
    cp -rf ./YAOF/PATCH/kernel/6.8_Better_data_locality_in_networking_fast_paths-bp_but_put_in_hack/* ./target/linux/generic/hack-${linux_version}/
    cp -rf ./YAOF/PATCH/kernel/6.8_Boost_TCP_Performance_For_Many_Concurrent_Connections-bp_but_put_in_hack/* ./target/linux/generic/hack-${linux_version}/
    cp -rf ./YAOF/PATCH/kernel/arm/* ./target/linux/generic/hack-${linux_version}/
rm -rf ./YAOF
else
p "BBRv3"
    clone bbr-v3 https://github.com/nasbdh9/openwrt ./bbrv3
    cp -rf ./bbrv3/target/linux/generic/hack-${linux_version}/601-* ./target/linux/generic/hack-${linux_version}/
    rm -rf ./bbrv3
p "复制 lrng 补丁"
    cp -rf ${lynndir}/patch/lrng/v60/* ./target/linux/generic/hack-${linux_version}/
    cp -rf ${lynndir}/patch/lrng/6.12/* ./target/linux/generic/hack-${linux_version}/
p "复制 mac80211 补丁"
    cp -rf ${lynndir}/patch/mac80211/* ./target/linux/generic/hack-${linux_version}/
p "复制 tcp-collapse 补丁"
    cp -rf ${lynndir}/patch/tcp-collapse/* ./target/linux/generic/hack-${linux_version}/
fi
# dont wrongly interpret first-time data
echo "net.netfilter.nf_conntrack_tcp_max_retrans=5" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf


p "LuCI 自定义 nft 规则页面"
patch -p1 < ${lynndir}/patch/fw4/100-openwrt-firewall4-add-custom-nft-command-support.patch
cp -f ${lynndir}/patch/fw4/100-fw4-add-custom-nft-command-support.patch ./package/network/config/firewall4/patches/
pushd feeds/luci
patch -p1 <${lynndir}/patch/fw4/0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd


p "SquashFS 支持 Zstd 和 LZ4"
patch -p1 <${lynndir}/patch/squashfs/squashfs4_add_zstd_lz4_support.patch
sed -i 's|^\$(curdir)/squashfs4/compile :=.*zlib/compile$|& \$(curdir)/zstd/compile \$(curdir)/lz4/compile|' ./tools/Makefile
# 这里的 `&` 代表匹配到的原始字符串。
# **`-i`**: 表示直接修改文件内容（In-place edit）。
# **`s|...|...|`**: 使用 `|` 作为分隔符，格式为 `s|旧字符串|新字符串|`。
# **`\$`**: 在正则表达式中 `$` 是特殊字符（表示行尾），匹配字面含义的 `$` 需要加反斜杠转义。
# **`g`**: 表示全局替换（如果一行中出现多次则全部替换）

p "默认开启 Irqbalance"
sed -i "s/enabled '0'/enabled '1'/g" ./feeds/packages/utils/irqbalance/files/irqbalance.config


p "追加配置"
echo "
# LRNG
CONFIG_PACKAGE_urandom-seed=n
CONFIG_PACKAGE_urngd=n

# Docker cgroup options
CONFIG_DOCKER_CGROUP_OPTIONS=n

# Log
CONFIG_DEVEL=y
CONFIG_BUILD_LOG=y
CONFIG_BUILD_LOG_DIR="./logs"

# Enable ccache
CONFIG_CCACHE=y

" >> .config_pending

CONFIG_CONTENT='
CONFIG_CPU_IDLE_GOV_MENU=n
CONFIG_CPU_IDLE_GOV_TEO=y

CONFIG_DEFAULT_BBR=y
CONFIG_DEFAULT_CUBIC=n
CONFIG_DEFAULT_TCP_CONG="bbr"
CONFIG_TCP_CONG_BBR=y

CONFIG_HZ=300
CONFIG_HZ_250=n
CONFIG_HZ_300=y

CONFIG_PREEMPT=y
CONFIG_PREEMPTION=y
CONFIG_PREEMPT_BUILD=y
CONFIG_PREEMPT_COUNT=y
# CONFIG_PREEMPT_NONE is not set
CONFIG_PREEMPT_RCU=y
CONFIG_TOOLS_SUPPORT_RELR=y
CONFIG_UNINLINE_SPIN_UNLOCK=y

CONFIG_LRU_GEN=y
CONFIG_LRU_GEN_ENABLED=y

# LRNG
CONFIG_RANDOM_DEFAULT_IMPL=n
CONFIG_LRNG=y
# CONFIG_LRNG_AIS2031_NTG1_SEEDING_STRATEGY is not set
CONFIG_LRNG_APT_CUTOFF=325
CONFIG_LRNG_APT_CUTOFF_PERMANENT=371
CONFIG_LRNG_COMMON_DEV_IF=y
CONFIG_LRNG_CPU=y
CONFIG_LRNG_CPU_ENTROPY_RATE=8
CONFIG_LRNG_CPU_FULL_ENT_MULTIPLIER=1
CONFIG_LRNG_DEV_IF=y
CONFIG_LRNG_DFLT_DRNG_CHACHA20=y
# CONFIG_LRNG_DFLT_DRNG_DRBG is not set
# CONFIG_LRNG_DFLT_DRNG_KCAPI is not set
CONFIG_LRNG_DRNG_CHACHA20=y
# CONFIG_LRNG_HWRAND_IF is not set
CONFIG_LRNG_JENT=y
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
# CONFIG_LRNG_KERNEL_RNG is not set
CONFIG_LRNG_RCT_CUTOFF=31
CONFIG_LRNG_RCT_CUTOFF_PERMANENT=81
# CONFIG_LRNG_RUNTIME_ES_CONFIG is not set
# CONFIG_LRNG_SCHED is not set
CONFIG_LRNG_SELFTEST=y
# CONFIG_LRNG_SELFTEST_PANIC is not set
CONFIG_LRNG_SHA256=y
# CONFIG_LRNG_SWITCH_DRNG is not set
# CONFIG_LRNG_SWITCH_HASH is not set
# CONFIG_LRNG_TESTING_MENU is not set
CONFIG_LRNG_AUTO_SELECTED=y
CONFIG_LRNG_COLLECTION_SIZE=1024
CONFIG_LRNG_COLLECTION_SIZE_1024=y
# CONFIG_LRNG_COLLECTION_SIZE_2048 is not set
# CONFIG_LRNG_COLLECTION_SIZE_256 is not set
# CONFIG_LRNG_COLLECTION_SIZE_32 is not set
# CONFIG_LRNG_COLLECTION_SIZE_4096 is not set
# CONFIG_LRNG_COLLECTION_SIZE_512 is not set
# CONFIG_LRNG_COLLECTION_SIZE_8192 is not set
# CONFIG_LRNG_CONTINUOUS_COMPRESSION_DISABLED is not set
CONFIG_LRNG_CONTINUOUS_COMPRESSION_ENABLED=y
CONFIG_LRNG_DRNG_ATOMIC=y
CONFIG_LRNG_ENABLE_CONTINUOUS_COMPRESSION=y
# CONFIG_LRNG_HEALTH_TESTS is not set
CONFIG_LRNG_IRQ=y
CONFIG_LRNG_IRQ_DFLT_TIMER_ES=y
CONFIG_LRNG_IRQ_ENTROPY_RATE=256
CONFIG_LRNG_RANDOM_IF=y
# CONFIG_LRNG_SWITCHABLE_CONTINUOUS_COMPRESSION is not set
CONFIG_LRNG_SYSCTL=y
CONFIG_LRNG_TIMER_COMMON=y

'
find ./target/linux/ -name "config-${linux_version}" | xargs -I{} sh -c "echo '$CONFIG_CONTENT' | tee -a {} > /dev/null"

# p "Vermagic 内核模块兼容" # 没有什么用
# # wget https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/targets/rockchip/armv8/profiles.json
# wget https://downloads.immortalwrt.org/snapshots/targets/rockchip/armv8/profiles.json # TODO
# jq -r '.linux_kernel.vermagic' profiles.json >.vermagic
# cat .vermagic
# sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
# rm -f profiles.json



p "复制自定义文件目录"
cp -rf ${lynndir}/files ./

p "容器内脚本结束"
