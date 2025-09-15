clone() {
  # 参数1: 分支名  参数2: 仓库地址  参数3: 目标目录
  if [ $# -lt 3 ]; then
    echo "用法: clone <branch> <repo_url> <target_dir>" >&2
    return 1
  fi
  local branch_name="$1" repo_url="$2" target_dir="$3"
  git clone -q -b "$branch_name" --depth 1 --single-branch --no-tags "$repo_url" "$target_dir"
}

echo "修改权限"
ls
sudo chown -R runner:runner ${workdir}

echo "设置 lynndir"
export lynndir="${PWD}" && echo "lynndir=${PWD}">> $GITHUB_ENV
echo "lynndir: ${lynndir}"

echo "设置临时目录"
export tmpdir=${workdir}/tmp && mkdir -p ${tmpdir}
echo "tmpdir=${tmpdir}" >> $GITHUB_ENV
export TMPDIR="${tmpdir}" && echo "TMPDIR=${tmpdir}" >> $GITHUB_ENV
export TEMP="${tmpdir}" && echo "TEMP=${tmpdir}" >> $GITHUB_ENV
export TEMPDIR="${tmpdir}" && echo "TEMPDIR=${tmpdir}" >> $GITHUB_ENV
export TMP="${tmpdir}" && echo "TMP=${tmpdir}" >> $GITHUB_ENV
echo "tmpdir: ${tmpdir}"

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
CUSTOM_DEPENDENCIES="liblz4-dev libffi-dev"
DEPENDENCY="${CUSTOM_DEPENDENCIES} ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev libz-dev lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd"
sudo -E apt-fast install -y -qq $DEPENDENCY
echo "清理 apt 缓存"
sudo -E apt-fast autoremove --purge -y
sudo -E apt-fast clean -y
echo "安装 linux 推荐的 llvm"
LLVM_VER="21.1.1"
LLVM_DIR="llvm-${LLVM_VER}-x86_64"
LLVM_FILE="${LLVM_DIR}.tar.xz"
wget -q https://mirrors.edge.kernel.org/pub/tools/llvm/files/${LLVM_FILE} && \
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

echo "克隆 immortalwrt"
export wrtdir="${workdir}/immortalwrt" && echo "wrtdir=${workdir}/immortalwrt">> $GITHUB_ENV
echo "wrtdir: ${wrtdir}"
clone ${branch} https://github.com/immortalwrt/immortalwrt.git ${wrtdir}
pushd ${wrtdir}
export linux_version=$(ls target/linux/rockchip/ | grep '^patches-' | sed 's/patches-//') && echo "linux_version=${linux_version}" >> $GITHUB_ENV
echo "linux_version: ${linux_version}"
popd

echo "结束"
