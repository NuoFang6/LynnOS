clone() {
  # 参数1: 分支名  参数2: 仓库地址  参数3: 目标目录
  if [ $# -lt 3 ]; then
    echo "用法: clone <branch> <repo_url> <target_dir>" >&2
    return 1
  fi
  local branch_name="$1" repo_url="$2" target_dir="$3"
  git clone -q -b "$branch_name" --depth 1 --single-branch --no-tags "$repo_url" "$target_dir"
}
set_env() {
  local key="$1"
  local val="$2"

  # 1. 在当前 Step 生效 (只取第一行，防止 export 失败)
  # 如果确定只有一行，直接 export 即可
  export "$key"="$val"

  # 2. 写入 $GITHUB_ENV (使用 GitHub 推荐的 EOF 语法，完美支持多行或特殊字符)
  {
    echo "${key}<<EOF"
    echo "$val"
    echo "EOF"
  } >> "$GITHUB_ENV"

  echo "✅ Env set: $key"
}


echo "修改权限"
ls
sudo chown -R runner:runner ${workdir}

echo "设置 lynndir"
set_env "lynndir" "${PWD}"

echo "设置临时目录"
mkdir -p "${workdir}/tmp"
set_env "tmpdir" "${workdir}/tmp"
set_env "TMPDIR" "${tmpdir}"
set_env "TEMP" "${tmpdir}"
set_env "TEMPDIR" "${tmpdir}"
set_env "TMP" "${tmpdir}"

echo "配置 git"
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global core.abbrev auto

echo "修改系统配置"
sudo timedatectl set-timezone 'Asia/Shanghai'

echo "安装 apt-fast"
sudo -E apt-get -qq update
/bin/bash -c "$(curl -sL https://git.io/vokNn)"
echo "安装编译依赖"
CUSTOM_DEPENDENCIES="liblz4-dev libffi-dev libfuse-dev"
DEPENDENCY="${CUSTOM_DEPENDENCIES} ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev libz-dev lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd"
sudo -E apt-fast install -y -qq $DEPENDENCY
echo "清理 apt 缓存"
sudo -E apt-fast autoremove --purge -y
sudo -E apt-fast clean -y


echo "安装 linux 推荐的 llvm"
LLVM_BASE_URL="https://mirrors.edge.kernel.org/pub/tools/llvm/files/"
LLVM_FILE=$(curl -s "${LLVM_BASE_URL}" | grep -o 'llvm-[0-9.]\+-x86_64\.tar\.xz' | sort -uV | tail -n 1)
LLVM_DIR="${LLVM_FILE%.tar.xz}"
LLVM_FILE_URL="${LLVM_BASE_URL}${LLVM_FILE}"
if [ -z "$LLVM_FILE_URL" ]; then
    echo "错误：无法自动获取最新版本的 LLVM"
    exit 1
fi
wget -q ${LLVM_FILE_URL} && \
tar -xf ${LLVM_FILE} && \
sudo -E cp -rf ${LLVM_DIR}/bin/* /usr/local/bin/ && \
sudo -E cp -rf ${LLVM_DIR}/lib/* /usr/local/lib/ && \
llvm-strip -V
rm -rf ${LLVM_FILE} ${LLVM_DIR}

echo "安装 rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q -y
source $HOME/.cargo/env
rustup -q default nightly
rustup -q target add aarch64-unknown-linux-musl

echo "子模块"
set_env "sbwml" "${workdir}/sbwml"

echo "克隆 immortalwrt"
set_env "wrtdir" "${workdir}/immortalwrt"
clone ${branch} https://github.com/immortalwrt/immortalwrt.git ${wrtdir}
pushd ${wrtdir}
git config core.fileMode false # 忽略权限变更
popd

echo "对比 linux 版本号"
linux_ver_immortal=$(sed -n 's/^KERNEL_PATCHVER:=//p' ${wrtdir}/target/linux/rockchip/Makefile)
linux_ver_sbwml=$(ls -d ${sbwml}/openwrt/patch/kernel-* | sed 's/.*kernel-//')
if [ "${linux_ver_immortal}" != "${linux_ver_sbwml}" ]; then
  echo "警告："
  echo "immortalwrt 的内核版本 (${linux_ver_immortal}) 与"
  echo "sbwml 的内核版本 (${linux_ver_sbwml}) 不匹配"
fi

echo "克隆 openwrt packages"
set_env "upstreampkg" "${workdir}/upstream/packages"
clone openwrt-24.10 https://github.com/openwrt/packages.git ${upstreampkg}

echo "其它来源"
set_env "extpkg" "${lynndir}/extpkg"

echo "结束"
