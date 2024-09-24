#!/bin/bash
export LC_ALL=C
export UUID=${UUID:-'39e8b439-06be-4783-ad52-6357fc5e8743'}         
export NEZHA_SERVER=${NEZHA_SERVER:-''}             
export NEZHA_PORT=${NEZHA_PORT:-'5555'}            
export NEZHA_KEY=${NEZHA_KEY:-''}
export PASSWORD=${PASSWORD:-'admin'} 
export PORT=${PORT:-'0000'}
USERNAME=$(whoami)
HOSTNAME=$(hostname)

# 设置工作目录
[[ "$HOSTNAME" == "s1.ct8.pl" ]] && WORKDIR="domains/${USER,,}.ct8.pl/logs" || WORKDIR="domains/${USERNAME}.serv00.net/logs"
[ -d "$WORKDIR" ] || (mkdir -p "$WORKDIR" && chmod 777 "$WORKDIR" && cd "$WORKDIR")
ps aux | grep $(whoami) | grep -v "sshd\|bash\|grep" | awk '{print $2}' | xargs -r kill -9

# 下载 TUIC 依赖文件
clear
echo -e "\e[1;35m正在安装中,请稍等...\e[0m"
ARCH=$(uname -m) && DOWNLOAD_DIR="." && mkdir -p "$DOWNLOAD_DIR"

# 根据系统架构下载对应的文件
if [ "$ARCH" == "amd64" ] || [ "$ARCH" == "x86_64" ]; then
    TUIC_URL="https://github.com/etjec4/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-x86_64-unknown-freebsd"
elif [ "$ARCH" == "arm" ] || [ "$ARCH" == "arm64" ] || [ "$ARCH" == "aarch64" ]; then
    TUIC_URL="https://github.com/etjec4/tuic/releases/download/tuic-server-1.0.0/tuic-server-1.0.0-arm64-unknown-freebsd"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# 下载 TUIC 文件
TUIC_FILE="$DOWNLOAD_DIR/tuic-server"
curl -L -o "$TUIC_FILE" "$TUIC_URL"
chmod +x "$TUIC_FILE"

# 生成 SSL 证书
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout $WORKDIR/server.key -out $WORKDIR/server.crt -subj "/CN=bing.com" -days 36500

# 生成 TUIC 配置文件
cat > config.json <<EOL
{
  "server": "[::]:$PORT",
  "users": {
    "$UUID": "$PASSWORD"
  },
  "certificate": "$WORKDIR/server.crt",
  "private_key": "$WORKDIR/server.key",
  "congestion_control": "bbr",
  "alpn": ["h3", "spdy/3.1"],
  "udp_relay_ipv6": true,
  "zero_rtt_handshake": false,
  "dual_stack": true,
  "auth_timeout": "3s",
  "task_negotiation_timeout": "3s",
  "max_idle_time": "10s",
  "max_external_packet_size": 1500,
  "gc_interval": "3s",
  "gc_lifetime": "15s",
  "log_level": "warn"
}
EOL

# 运行 TUIC
run() {
    nohup "$TUIC_FILE" -c config.json >/dev/null 2>&1 &
    sleep 1
    pgrep -x "$(basename "$TUIC_FILE")" > /dev/null && echo -e "\e[1;32mTUIC is running\e[0m" || { 
        echo -e "\e[1;35mTUIC is not running, restarting...\e[0m"
        pkill -f "$(basename "$TUIC_FILE")"
        nohup "$TUIC_FILE" -c config.json >/dev/null 2>&1 &
        sleep 2
        echo -e "\e[1;32mTUIC restarted\e[0m"
    }
}

run

# 获取外网 IP 并输出 TUIC 链接
HOST_IP=$(curl -s ifconfig.me || echo "0.0.0.0")
echo -e "\n\e[1;35m以下是您的链接:\e[0m\n"
echo -e "\e[1;32mtuic://$UUID@$HOST_IP:$PORT#$ISP\e[0m\n"

wait
