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
umask 0022 && getfacl -d .
clone ${immortalwrt_branch} https://github.com/immortalwrt/immortalwrt ${wrtdir}
pushd ${wrtdir}
git config core.filemode false # 忽略权限变更
popd





p ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"

p "进入编译目录 ${wrtdir}"
cd ${wrtdir}


p "检查内核版本"
# 定义预期的内核版本
SUPPORTED_KERNEL="6.12"
current_version=$(sed -n 's/^KERNEL_PATCHVER:=//p' ./target/linux/rockchip/Makefile) # 如 6.12
if [ -z "${current_version}" ]; then
    echo "Error: Failed to extract KERNEL_PATCHVER from ./target/linux/rockchip/Makefile"
    exit 1
fi
if [[ "${SUPPORTED_KERNEL}" != "${current_version}" ]]; then
    echo "##########
      错误：
      编译的内核版本为 ${current_version} ，
      预期的版本为 ${SUPPORTED_KERNEL}
    ##########"
    exit 1
fi
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
# p "替换 utils/cgroupfs-mount" #TODO cgroupfs-mount numactl libnuma
# mkdir -p feeds/packages/utils/
# cp -rf ${upstream_packages}/utils/cgroupfs-mount ./feeds/packages/utils/
# p "降级 rust"
# rm -rf feeds/packages/lang/rust
# cp -rf ${upstream_packages}/lang/rust ./feeds/packages/lang/
# p "替换 node-ffi-napi"
# cp -f ${upstream_packages}/libs/libffi/Makefile ./package/feeds/packages/libffi/Makefile
# patch -p0 < ${lynndir}/patch/uwsgi/Makefile.patch
# patch -p0 < ${lynndir}/patch/btrfs-progs/Makefile.patch
# patch -p1 < ${lynndir}/patch/fullconenat-nft/Makefile.patch
# patch -p0 < ${lynndir}/patch/rust/Makefile.patch




p "应用自定义修改"
p "BBRv3"
cp -rf ${lynndir}/patch/bbrv3/linux/* ./target/linux/generic/hack-${linux_version}/
cp -rf ${lynndir}/patch/bbrv3/iproute2/* ./package/network/utils/iproute2/patches/
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
# **`g`**: 表示全局替换（如果一行中出现多次则全部替换）。

p "启用 LRNG" # TODO
echo "
# Kernel - LRNG
CONFIG_KERNEL_LRNG=y
CONFIG_PACKAGE_urandom-seed=n
CONFIG_PACKAGE_urngd=n
# Docker cgroup options
CONFIG_DOCKER_CGROUP_OPTIONS=n
" >> .config_pending


# p "Vermagic 内核模块兼容" # 没有什么用
# # wget https://downloads.immortalwrt.org/releases/24.10-SNAPSHOT/targets/rockchip/armv8/profiles.json
# wget https://downloads.immortalwrt.org/snapshots/targets/rockchip/armv8/profiles.json # TODO
# jq -r '.linux_kernel.vermagic' profiles.json >.vermagic
# cat .vermagic
# sed -i -e 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
# rm -f profiles.json


# p "修复缺失的必要内核参数"
# sed -i 's/^CONFIG_FRAME_WARN=.*/# &/' ./target/linux/generic/config-filter
# CONFIG_CONTENT='
# CONFIG_FRAME_WARN=2048
# '
# find ./target/linux/ -name "config-${linux_version}" | xargs -I{} sh -c "echo '$CONFIG_CONTENT' | tee -a {} > /dev/null"

p "复制自定义文件目录"
cp -rf ${lynndir}/files ./

p "容器内脚本结束"
