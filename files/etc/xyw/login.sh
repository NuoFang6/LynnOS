#!/bin/bash
# 尽量快速退出，减少占用 ############
ping -c 1 -W 1 223.5.5.5 >/dev/null
if [[ $? -eq 0 ]]; then
    logger '网络连接正常，脚本退出。'
    exit
fi
####################################

# 变量配置区 #
#
# 填写抓取到的网址
URL=''
# 登录成功时会出现的唯一关键词
SUCCESS_WORD='result":1'
# 用户已经在线时的关键词
ONLINE_WORD='已经在线'
# 网关IP
GatewayIP='10.31.0.10'
# 日志目录
LOG_PATH="/etc/xyw/log.txt"
# 失败几次后停止尝试
TEST_CNT=3
# 阿里DNS
PING_URLa='223.5.5.5'
# 腾讯DNS
PING_URLb='119.29.29.29'

# 工具方法
pingtest() {
    local target=$1
    ping -c 1 -W 1 $target >/dev/null
}

log() {
    local message=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    # 获取日志目录的上级目录
    local log_dir=$(dirname "$LOG_PATH")

    # 检查上级目录是否存在，如果不存在则创建
    if [ ! -d "$log_dir" ]; then
        mkdir -p "$log_dir" || { echo "log目录创建失败！" >&2; }
    fi
    echo "[$timestamp] $message" | tee -a $LOG_PATH | logger
}

login() {
    content=$(curl -fs "$URL")

    if [ $? -ne 0 ]; then
        log "curl命令失败，错误代码：$?"
        return 1
    fi

    # 检查是否已经在线
    if echo "$content" | grep -qF "$ONLINE_WORD"; then
        log "用户已经在线，脚本退出。"
        exit 0
    fi

    # 检查是否登录成功
    if echo "$content" | grep -qF "$SUCCESS_WORD"; then
        return 0
    fi

    log "登录失败（$content）"
    return 1
}

NOW_CNT=0
# -lt 小于运算符
while [ $NOW_CNT -lt $TEST_CNT ]; do
    # 校园网关
    pingtest $GatewayIP
    gateway_ret=$?

    pingtest $PING_URLb
    if [[ $? -eq 0 ]]; then
        log '网络连接正常，脚本退出。'
        exit
        # 开始登录
    elif [[ $gateway_ret -eq 0 ]]; then
        log '互联网连接失败，开始尝试登录校园网'
        login
        # 登录成功时
        if [[ $? -eq 0 ]]; then
            log '校园网登录成功，开始检查网络是否正常'
            sleep 3
            pingtest $PING_URLa
            if [ $? -eq 0 ]; then
                log '网络正常，脚本结束。'
                exit
                # 登录但连不上互联网时
            else
                log '网络连接仍然失败，等待再次测试'
                sleep 3
                pingtest $PING_URLb
                if [ $? -eq 0 ]; then
                    log '网络正常，脚本结束。'
                    exit
                else
                    let "NOW_CNT++"
                    log "网络连接仍然失败，等待重试（第 $NOW_CNT 次）"
                fi
            fi
        else
            let "NOW_CNT++"
            log "校园网登录失败，等待重试（第 $NOW_CNT 次）"
        fi
        # ping不通网关时
    else
        log '不是校园网环境（无法ping通网关），脚本退出'
        exit
    fi
    sleep 5
done
log '仍然失败，脚本退出'
exit
