CUSTOM_DEPENDENCIES="liblz4-dev libffi-dev"
DEPENDENCY="${CUSTOM_DEPENDENCIES} ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev libreadline-dev libssl-dev libtool libyaml-dev libz-dev lld llvm lrzsz mkisofs msmtp nano ninja-build p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev zstd"

cd $lynndir
echo "进入项目根目录：$lynndir"

echo "修改临时目录"
TMPDIR=${lynndir}/../tmp
mkdir -p $TMPDIR
pushd $TMPDIR
export TMPDIR="$PWD" && echo "TMPDIR=$PWD" >> $GITHUB_ENV
echo "TMPDIR: $TMPDIR"
popd

echo "配置 git"
git config --global user.name "github-actions[bot]"
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global core.abbrev auto


echo "修改系统配置"
sudo timedatectl set-timezone 'Asia/Shanghai'


echo "删除并禁用 snap"
{
set +e # 关闭自动退出
sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
while [ "$sum" -ne 0 ]; do
    for p in $(snap list | awk 'NR>=2{print $1}'); do
        sudo snap remove --purge "$p"
    done
    sum=$(snap list | awk 'NR>=2{print $1}' | wc -l)
done
sudo systemctl stop snapd
sudo systemctl disable --now snapd.socket
for m in /snap/core/*; do
  sudo umount $m
done
sudo apt autoremove --purge snapd -y
sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
sudo rm -rf /var/cache/snapd
echo -e "\nPackage: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
echo -e "\nPackage: firefox\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/no-firefox.pref
set -e # 重新开启自动退出
} >/dev/null


echo "安装 apt-fast"
sudo mv -f ./scripts/ubuntu.sources /etc/apt/sources.list.d/ # 替换源
/bin/bash -c "$(curl -sL https://git.io/vokNn)"
sudo -E cp -rf ./scripts/apt-fast.conf /etc


echo "安装编译依赖"
{ 
sudo -E apt-fast update -y
if [ "${needBuild}" = "true" ]; then
  sudo -E apt-fast dist-upgrade -y
  # sudo -E apt-fast upgrade -y
fi
sudo -E apt-fast dist-upgrade -y
sudo -E apt-fast install -y $DEPENDENCY
sudo -E apt-fast autoremove --purge -y
sudo -E apt-fast clean -y
} >/dev/null


sudo chown -R runner:runner /home/runner/work/LynnOS
# 以下不能是sudo
echo "安装 rust"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -q -y
source $HOME/.cargo/env
rustup -q default nightly
rustup -q target add aarch64-unknown-linux-musl

echo "克隆 immortalwrt"
git clone -q -b ${branch} --depth 1 --single-branch https://github.com/immortalwrt/immortalwrt.git ${lynndir}/../immortalwrt
pushd ${lynndir}/../immortalwrt
ls
export wrtdir="$PWD" && echo "wrtdir=$PWD">> $GITHUB_ENV
echo "wrtdir: $wrtdir"
popd