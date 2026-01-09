这是一个还在开发的openwrt编译脚本。  
This is an openwrt compilation script that is still under development.

---

- [ ] 基本优化
  - [ ] 超频至 1.6
  - [ ] BBRv3
  - [ ] 硬件加密/加速 (Rockchip Crypto是负优化)
  - [ ] QUIC 参数
  - [ ] 自带默认配置
  - [ ] Docker
  - [ ] 禁用 GPU
- [ ] 其它优化
  - [ ] LRNG
  - [ ] irq 优化
  - [ ] O3编译
  - [ ] 针对 Cortex-A53 编译
  - [ ] LTO 优化
  - [ ] Voluntary Kernel Preemption
  - [ ] multigen_lru
  - [ ] kernel.sched_bore
  - [ ] SCHED_AUTOGROUP
  - [ ] scx内核支持
  - [ ] adios
  - [ ] fullcone
  - [ ] 电压调节
  - [ ] 在线 OTA 更新
  - [ ] 6.18 内核
  - [ ] 300Hz
- [ ] 编译流程优化
  - [ ] 使用cachyos中优化的包
  - [ ] 复用缓存
  - [ ] 更换 projectsmirrors.json 顺序
  - [ ] 复用工具链

---
- [ ] 开启特性 
  - [ ] eBPF
  - [ ] btrfs
  - [ ] 兼容通用架构的包
  - [ ] zram 算法
  - [ ] cake 等队列算法
- [ ] 软件包
  - [ ] UA3F
  - [ ] EasyTier
  - [ ] rt2000
  - [ ] zsh
  - [ ] tcp-brutal

强制性
[ ] 关闭 qBittorrent-Enhanced-Edition
[ ] 不要编译 qt