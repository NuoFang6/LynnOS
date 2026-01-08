sudo timedatectl set-timezone 'Asia/Shanghai'

echo "创建快捷命令"
bin_host="${HOME}/bin_host"
mkdir -p $bin_host
# p: 打印日志
cat <<'EOF' > $bin_host/p
#!/bin/bash
echo "    >> $*"
EOF
# d: 以 runner 身份在容器内执行命令并打印日志
cat <<'EOF' > $bin_host/d
#!/bin/bash
p "runner@cachyos: $*"
docker exec -u runner -e BASH_ENV=${workdir}/ci_env cachyos bash -c "$*"
EOF
# dr: 以 root 身份在容器内执行命令并打印日志
cat <<'EOF' > $bin_host/dr
#!/bin/bash
p "root@cachyos: $*"
docker exec -u root -e BASH_ENV=${workdir}/ci_env cachyos bash -c "$*"
EOF
# clone: git克隆，参数1: 分支名 参数2: 仓库地址 参数3: 目标目录
cat <<'EOF' > $bin_host/clone
#!/bin/bash
if [ $# -lt 2 ]; then
  echo "用法: clone <branch> <repo_url> <target_dir>" >&2
  return 1
fi
p "浅克隆: $2 (branch: $1) $3"
git clone -q -b "$1" --filter=blob:none --single-branch --no-tags "$2" "$3"
EOF
# set_env: 设置环境变量
# 1. 输出日志
# 2. 导出到当前 Shell (供当前脚本立即使用)
# 3. 写入 BASH_ENV 文件 (供容器内后续所有 Bash 自动读取)
# 4. 写入 GITHUB_ENV (供 Workflow 后续步骤使用)
# 容器内的持久化环境文件路径
CI_ENV_FILE="${workdir}/ci_env"
cat <<EOF > $bin_host/set_env
#!/bin/bash
p "set_env: \$1 = \$2"
export "\$1"="\$2"
if [ -w "$CI_ENV_FILE" ]; then
    echo "export \$1=\"\$2\"" >> $CI_ENV_FILE
fi
echo "\$1=\$2" >> \$GITHUB_ENV
EOF
chmod +x $bin_host/*
echo "$bin_host" >> $GITHUB_PATH
export PATH="$bin_host:$PATH"



p "打印可用空间"
df -h



p "准备 CachyOS"
. set_env "workdir" "/ci"  # 必须使用 . set_env ，否则变量不会在当前 shell 生效
. set_env "workdir_out" "/mnt${workdir}"
. set_env "lynndir" "${workdir}/lynnos"

sudo mkdir ${workdir_out} && sudo chown -R runner:runner ${workdir_out}

# -v ${workdir_out}:${workdir}: 挂载工作目录
# -v $bin_host:/usr/local/bin_host: 将快捷命令挂载进去
# -v $GH_ENV_DIR:$GH_ENV_DIR: 挂载 GitHub 环境文件目录
# -e GITHUB_ENV=$GITHUB_ENV: 告诉容器环境变量文件路径，可以写入但不能读
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
  -e workdir="${workdir}" \
  -e lynndir="${lynndir}" \
  -e BASH_ENV="${workdir}/ci_env" \
  -w ${workdir} \
  cachyos/cachyos-v3 tail -f /dev/null

p "初始化容器环境文件"
# 先创建文件并授权，这样容器内的 set_env 才能写入
dr "touch ${workdir}/ci_env"
dr "chmod 777 ${workdir}/ci_env"
# 将初始变量写入容器的持久化文件，供后续 exec 使用
dr "echo 'export workdir=\"${workdir}\"' >> ${workdir}/ci_env"
dr "echo 'export lynndir=\"${lynndir}\"' >> ${workdir}/ci_env"



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
dr "chown -R runner:runner /home/runner"

p "d 命令已可用"

p "设置临时目录"
dr "chmod 777 /tmp"
d '
  mkdir -p "${workdir}/tmp"
  . set_env "tmpdir" "${workdir}/tmp"
  . set_env "TMPDIR" "${tmpdir}"
  . set_env "TEMP" "${tmpdir}"
  . set_env "TEMPDIR" "${tmpdir}"
  . set_env "TMP" "${tmpdir}"
'

d paru --noconfirm -S ack antlr3


p "复制仓库到容器内 ${lynndir}"
cp -r $GITHUB_WORKSPACE ${workdir_out}/lynnos

p "外部脚本结束"