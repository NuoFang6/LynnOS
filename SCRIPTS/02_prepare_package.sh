#!/bin/bash
clear

### 基础部分 ###
# 使用 O3 级别的优化
sed -i 's/-Os/-O3/g' include/target.mk
# 更新 Feeds
./scripts/feeds update -a
./scripts/feeds install -a
# # 默认开启 Irqbalance
# sed -i "s/enabled '0'/enabled '1'/g" feeds/packages/utils/irqbalance/files/irqbalance.config

echo "net.netfilter.nf_conntrack_helper = 1" >>./package/kernel/linux/files/sysctl-nf-conntrack.conf
# Nginx
sed -i "s/large_client_header_buffers 2 1k/large_client_header_buffers 4 32k/g" feeds/packages/net/nginx-util/files/uci.conf.template
sed -i "s/client_max_body_size 128M/client_max_body_size 2048M/g" feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/client_max_body_size/a\\tclient_body_buffer_size 8192M;' feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/client_max_body_size/a\\tserver_names_hash_bucket_size 128;' feeds/packages/net/nginx-util/files/uci.conf.template
sed -i '/ubus_parallel_req/a\        ubus_script_timeout 600;' feeds/packages/net/nginx/files-luci-support/60_nginx-luci-support
sed -ri "/luci-webui.socket/i\ \t\tuwsgi_send_timeout 600\;\n\t\tuwsgi_connect_timeout 600\;\n\t\tuwsgi_read_timeout 600\;" feeds/packages/net/nginx/files-luci-support/luci.locations
sed -ri "/luci-cgi_io.socket/i\ \t\tuwsgi_send_timeout 600\;\n\t\tuwsgi_connect_timeout 600\;\n\t\tuwsgi_read_timeout 600\;" feeds/packages/net/nginx/files-luci-support/luci.locations

# Disable Mitigations
sed -i 's,rootwait,rootwait mitigations=off,g' target/linux/rockchip/image/default.bootscript

### 获取额外的 LuCI 应用、主题和依赖 ###
# 非源码 ipk
# UA3F
mkdir -p ../PATCH/files/etc/preinstall/
wget -q -O ../PATCH/files/etc/preinstall/ua3f_armv8.ipk $(curl -s https://api.github.com/repos/SunBK201/UA3F/releases/latest | grep browser_download_url | grep armv8.ipk | cut -d '"' -f 4) &
# 源码
# 广告过滤 AdGuard、wrtbwmond等
git clone --depth 1 https://github.com/sirpdboy/sirpdboy-package.git package/sirpdboy-package
# OpenClash
git clone -b master --single-branch --depth 1 https://github.com/vernesong/OpenClash.git package/new/luci-app-openclash
# ServerChan 微信推送
git clone -b master --depth 1 https://github.com/tty228/luci-app-wechatpush.git package/new/luci-app-serverchan


### 最后的收尾工作 ###
# 修改默认ip
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
# 拒绝🐕‍🦺叫警告
rm -rf package/feeds/telephony/freeswitch/ &
rm -rf package/feeds/telephony/freetdm/ &
rm -rf package/feeds/telephony/freeswitch-mod-bcg729/ &
rm -rf package/sirpdboy-package/luci-app-control-timewol/ &
# 无法编译的包
rm -rf package/feeds/packages/net/wsdd2


wait

# exit 0
