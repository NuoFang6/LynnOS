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
clone ${immortalwrt_branch} https://github.com/immortalwrt/immortalwrt ${wrtdir}
pushd ${wrtdir}
git config core.filemode false # 忽略权限变更
popd



p "克隆 openwrt packages"
. set_env "upstream_packages" "${workdir}/upstream/packages"
clone openwrt-25.12 https://github.com/openwrt/packages.git ${upstream_packages} # TODO: 自动检测稳定版分支名



p "容器内脚本结束"
