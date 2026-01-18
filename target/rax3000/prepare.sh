# TODO
p "复制种子配置" # ./scripts/diffconfig.sh > diffconfig 生成
cp -f ${targetdir}/seed.config .config

p "使用专属优化选项"
patch -p1 < ${targetdir}/target.mk.patch

p "修改内核配置" # make kernel_nconfig CONFIG_TARGET=target、subtarget、env
find ./target/linux/ -name "config-${linux_version}" | xargs -I{} sh -c "cat ${targetdir}/kernel.config | tee -a {} > /dev/null"