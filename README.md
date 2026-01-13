Still under develop...  

---
### 这是 深入、简洁、可长期扩展 的自定义openwrt编译脚本

## 使用方式
1. 下载发行版 或 actions LynnOS-build 里的 Artifacts
2. 解压得到固件，按照对应平台的方法刷写

## 如何添加自己的设备
1. 项目分为**通用修改**和**特定于设备的修改**，请在`target`里新建一个`你的设备名`文件夹，如`target/r2s`
2. 修改`.github/workflows/LynnOS-build.yml`工作流，传递正确的`${{ github.event.inputs.target }}`（你的设备名）
3. 新建`target/你的设备名/prepare.sh`，至少要完成`.config`的覆盖
4. 始终在`设备名`文件夹下存放对源码的修改，且不应该干扰其它目标；**除非其它设备也能受益**
5. `prepare/init-out.sh` 顶部定义了一些快捷工具，其它部分也定义了一些快捷变量，推荐使用。
6. 调整通用修改时记得和使用不同目标的人商量（如有）；尽量小写变量名，多打换行；

## 项目结构
```
.
|-- files （此文件夹会复制到编译目录，*不要放其它东西*）
|   `-- etc
|       `-- uci-defaults （第一次启动脚本文件夹，设备首次启动或更新后会运行一次里面的所有脚本）
|           `-- 98-custom （所有目标都会包含这个脚本）
|-- patch （存放通用的补丁或修改）
|   `-- 某个修改的名称
|       |-- 这个修改所需的文件...
|       `-- .patch 文件
|-- prepare （存放通用修改脚本）
|   |-- init-in.sh （将在容器内运行）
|   `-- init-out.sh （在容器外运行的脚本）
|-- target
|   `-- 目标名
|       |-- prepare.sh （将在 init-in.sh 之后运行）
|       `-- seed.config （推荐使用种子/差异配置文件，需要手动覆盖）
`-- tools （存放可能会用到的的工具脚本）
    `-- ... sh 文件
```
files 文件夹的用途：https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#custom_files  
uci-defaults 脚本：https://openwrt.org/docs/guide-developer/uci-defaults  
seed.config 配置：https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#diff_file  

#### 目前基于 [immortalwrt](https://github.com/immortalwrt/immortalwrt) 的主线分支

---
## TODO List
### 通用
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


### [ ] 特定于 R2s  
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

### [ ] 特定于 CMCC RAX3000M NAND
- [ ] 调整
  - [ ] web 救砖界面
  - [ ] 储存布局
  - [ ] 闭源驱动
  - [ ] 硬件卸载
  - TODO

- [ ] 软件包
  - [ ] mtd 工具
  - [ ] 交换机相关

---
#### 感谢所有开发者
#### 如果有违反相关 License ，请告诉我。