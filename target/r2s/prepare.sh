p "权限状态"
ls -l
id

p "复制种子配置" # ./scripts/diffconfig.sh > diffconfig 生成
cp -f ${targetdir}/seed.config .config

p "复制首次启动配置脚本"
cp -f ${targetdir}/99-custom_target ./files/etc/uci-defaults/

p "超频"
cp -f ${targetdir}/991-arm64-dts-rockchip-add-more-cpu-operating-points-for.patch ./target/linux/rockchip/patches-${linux_version}

p "使用 O2 级别的优化、使用专属优化"
patch -p1 < ${targetdir}/target.mk.patch

p "交换 LAN/WAN 口"
network_conf="./target/linux/rockchip/armv8/base-files/etc/board.d/02_network"
sed -i 's,"eth1" "eth0","eth0" "eth1",g' "$network_conf"
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" "$network_conf"



p "修改内核配置" # make kernel_nconfig CONFIG_TARGET=target、subtarget、env
find ./target/linux/ -name "config-${linux_version}" | xargs -I{} sh -c "cat ${targetdir}/kernel.config | tee -a '{}' > /dev/null"

echo "结束"