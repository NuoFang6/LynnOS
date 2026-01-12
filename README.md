这是一个还在开发的openwrt编译脚本。  
This is an openwrt compilation script that is still under development.

---
## 通用
- [ ] 调整
  - [ ] BBRv3
  - [ ] QUIC 参数
  - [ ] 自带默认配置
  - [ ] LRNG
  - [ ] irq 优化
  - [ ] LTO 优化
  - [ ] MOLD 链接器
  - [ ] Kernel Preemption （Lazy）
  - [ ] multigen_lru
  - [ ] 300Hz
  - [ ] eBPF
  - [ ] 多种文件系统支持
  - [ ] 兼容通用架构的包
  - [ ] zram 算法
  - [ ] cake 等队列算法
  - [ ] 本地 kmod 源
  - [ ] 每周编译
  - [ ] 在线 OTA 更新
  - [ ] CPU 性能调节
  - [ ] Nginx（quic）替换 uhttpd
  - [ ] 6.18 内核
  - ~~[ ] Vermagic 兼容~~
  - ~~[ ] LLVM 编译~~ **兼容性过差**
  - ~~[ ] adios~~ **可能属于过度优化**
  - ~~[ ] sched_bore~~ **不适用于网络设备**
  - ~~[ ] BCM 全锥型 NAT~~ **收益不高**
  - ~~[ ] Shortcut-FE~~ **为什么不用自带的呢**
  - ~~[ ] natflow~~ **同上**

- [ ]软件包
  - [ ] 替换 adguardhome
  - [ ] poweroffdevice
  - [ ] 美化终端
  - [ ] CURL HTTP3/QUIC 支持
  - [ ] nano
  - [ ] SQM 列队管理
  - [ ] UPnP

- [ ] 编译流程
  - [x] 使用Cachyos优化的软件包
  - [ ] 更换镜像源
  - [ ] 更换 projectsmirrors.json 顺序
  - [ ] 复用缓存
  - [ ] 复用工具链
  - [ ] 并行clone
  - ~~[ ] 中文日志~~ **不兼容**


## [ ] 特定于 R2s  
- [ ] 调整
  - [ ] armv8 硬件加密扩展
  - [ ] 针对 Cortex-A53 编译
  - [ ] 超频
  - [ ] 降压
  - [ ] 电压调节支持
  - [ ] btrfs 系统固件
  - [ ] led 触发器
  - ~~[ ] O3编译~~ **弱芯片收益存疑，反而可能导致负优化**
  - ~~[ ] 驱动GPU~~ **没有什么用**
  - ~~[ ] 硬件随机数~~ **慢且没必要，质量也不高**
  - ~~[ ] Rockchip Crypto 加密引擎~~ **不如 Arm 提供的加密扩展**
  - ~~[ ] scx内核支持~~ **收益低**
  - ~~[ ] KVM 虚拟化~~ **应该是用不上的**
- [ ] 软件包
  - [ ] UA3F
  - [ ] EasyTier
  - [ ] rt2000
  - [ ] zsh
  - [ ] tcp-brutal
  - [ ] Docker（nftables）
  - [ ] q （DNS查询工具）
  - [ ] 完整 vim 替换 vi
  - [ ] Samba
  - ~~[ ] qBittorrent-Enhanced-Edition~~ **编译这个极其消耗时间**

## [ ] 特定于 CMCC RAX3000M NAND
- [ ] 调整
  - [ ] web 救砖界面
  - [ ] 储存布局
  - [ ] 闭源驱动
  - [ ] 硬件卸载
  - TODO

- [ ] 软件包
  - [ ] mtd 工具
  - [ ] 交换机相关