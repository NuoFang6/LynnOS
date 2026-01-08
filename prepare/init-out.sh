sudo timedatectl set-timezone 'Asia/Shanghai'

echo "创建快捷命令"
bin_host="${HOME}/bin_host"
mkdir -p $bin_host
# p: 打印日志
cat <<'EOF' > $bin_host/p
#!/bin/bash
echo ">>> $*"
EOF
# d: 以 runner 身份在容器内执行命令并打印日志
cat <<'EOF' > $bin_host/d
#!/bin/bash
p "runner@cachyos: $*"
docker exec -u runner cachyos bash -c "$*"
EOF
# dr: 以 root 身份在容器内执行命令并打印日志
cat <<'EOF' > $bin_host/dr
#!/bin/bash
p "root@cachyos: $*"
docker exec -u root cachyos bash -c "$*"
EOF
# clone: git浅克隆，参数1: 分支名 参数2: 仓库地址 参数3: 目标目录
cat <<'EOF' > $bin_host/clone
#!/bin/bash
if [ $# -lt 2 ]; then
  echo "用法: clone <branch> <repo_url> <target_dir>" >&2
  return 1
fi
p "浅克隆: $2 (branch: $1) $3"
git clone -q -b "$1" --depth 1 --single-branch --no-tags "$2" "$3"
EOF
# set_env: 设置环境变量，参数1: 变量名 参数2: 变量值
cat <<'EOF' > $bin_host/set_env
p "set_env: $1 = $2"
export "$1"="$2" && echo "$1=$2" >> $GITHUB_ENV
EOF
chmod +x $bin_host/*
echo "$bin_host" >> $GITHUB_PATH
export PATH="$bin_host:$PATH"



p "打印可用空间"
df -h



p "准备 CachyOS"
set_env "workdir_out" "/mnt/ci"
set_env "workdir" "/ci"
sudo mkdir ${workdir_out} && sudo chown -R runner:runner ${workdir_out}

# -v ${workdir_out}:${workdir}: 挂载工作目录
# -v $bin_host:/usr/local/bin_host: 将快捷命令挂载进去
# -v $GH_ENV_DIR:$GH_ENV_DIR: 挂载 GitHub 环境文件目录
# -e GITHUB_ENV=$GITHUB_ENV: 告诉容器环境变量文件路径
# -e GITHUB_PATH=$GITHUB_PATH: 告诉容器 PATH 文件路径
# -e PATH="/usr/local/bin_host:$PATH": 将挂载的脚本目录加入容器的 PATH
# -w ${workdir}: 设置工作目录
# tail -f /dev/null: 保持容器运行
GH_ENV_DIR=$(dirname "$GITHUB_ENV")
GH_PATH_DIR=$(dirname "$GITHUB_PATH")
docker pull cachyos/cachyos-v3
docker run -d --name cachyos \
  -v ${workdir_out}:${workdir} \
  -v "$bin_host:/usr/local/bin_host" \
  -v "$GH_ENV_DIR:$GH_ENV_DIR" \
  -v "$GH_PATH_DIR:$GH_PATH_DIR" \
  -e GITHUB_ENV="$GITHUB_ENV" \
  -e GITHUB_PATH="$GITHUB_PATH" \
  -e PATH="/usr/local/bin_host:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" \
  -w ${workdir} \
  cachyos/cachyos-v3 tail -f /dev/null



p "安装依赖"
dr pacman -Syu --noconfirm
dr pacman -S --needed --noconfirm base-devel asciidoc autoconf automake binutils bison \
  bzip2 ccache clang cmake cpio curl dtc eclipse-ecj fastjar flex gawk gettext \
  gcc-multilib git gnutls gperf haveged help2man intltool lib32-gcc-libs lib32-glibc \
  libelf glib2 gmp libtool libmpc mpfr ncurses python python-pip python-ply \
  python-docutils python-pyelftools qemu-img re2c rsync scons squashfs-tools \
  subversion swig texinfo uglify-js upx unzip wget xmlto xxd zstd 7zip \
  paru sudo shadow



p "确保用户一致并配置 sudo"
dr "groupadd -g $(id -g runner) runner || true;"
dr "useradd -u $(id -u runner) -g $(id -g runner) -m -s /bin/bash runner;"
dr "echo 'runner ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/runner;" # 涉及运算符，需要用引号括起来，避免歧义
dr "chmod 0440 /etc/sudoers.d/runner;"
d paru --noconfirm -S ack antlr3


p "复制仓库到容器内 ${workdir}/lynnos"
cp -r $GITHUB_WORKSPACE ${workdir_out}/lynnos
set_env "lynndir" "${workdir}/lynnos"

p "外部脚本结束"