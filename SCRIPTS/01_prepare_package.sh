#!/bin/bash
clear

# 使用 O3 级别的优化
sed -i 's/-Os/-O3/g' include/target.mk

# 自定义feed源
cp -rf ../feeds.conf.default ./feeds.conf.default
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a

### 获取额外的 LuCI 应用、主题和依赖 ###
# 非源码 ipk
# UA3F
mkdir -p ../PATCH/files/etc/preinstall/
wget -q -O ../PATCH/files/etc/preinstall/ua3f_armv8.ipk $(curl -s https://api.github.com/repos/SunBK201/UA3F/releases/latest | grep browser_download_url | grep armv8.ipk | cut -d '"' -f 4) &
# 源码
# OpenClash
git clone -b master --single-branch --depth 1 https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
# 有问题的
rm -rf package/sirpdboy-package/luci-app-control-timewol/ &

### 最后的收尾工作 ###
# 修改默认ip
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
# 默认开启 Irqbalance
# sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config
echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# 关闭缓解措施
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript
# Nginx
sed -i "s/large_client_header_buffers 2 1k/large_client_header_buffers 4 32k/g" feeds/packages/net/nginx-util/files/uci.conf.template
sed -i "s/client_max_body_size 128M/client_max_body_size 2048M/g" feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/client_max_body_size/a\\tclient_body_buffer_size 8192M;' feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/client_max_body_size/a\\tserver_names_hash_bucket_size 128;' feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 600;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -ri "/luci-webui.socket/i\ \t\tuwsgi_send_timeout 600\;\n\t\tuwsgi_connect_timeout 600\;\n\t\tuwsgi_read_timeout 600\;" feeds/packages/net/nginx/files-luci-support/luci.locations
sed -ri "/luci-cgi_io.socket/i\ \t\tuwsgi_send_timeout 600\;\n\t\tuwsgi_connect_timeout 600\;\n\t\tuwsgi_read_timeout 600\;" feeds/packages/net/nginx/files-luci-support/luci.locations

# 预配置文件
cp -rf ../PATCH/files ./files

wait
