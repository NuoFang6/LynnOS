#!/bin/bash
clear

# 使用专属优化
sed -i 's,-mcpu=generic,-march=armv8-a,g' include/target.mk

# 交换 LAN/WAN 口
sed -i 's,"eth1" "eth0","eth0" "eth1",g' target/linux/rockchip/armv8/base-files/etc/board.d/02_network
sed -i "s,'eth1' 'eth0','eth0' 'eth1',g" target/linux/rockchip/armv8/base-files/etc/board.d/02_network

# 预配置文件
cp -rf ../PATCH/files ./files

chmod -R 755 ./
find ./ -name *.orig | xargs rm -f &
find ./ -name *.rej | xargs rm -f

#exit 0
