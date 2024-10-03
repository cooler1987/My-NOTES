#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# Check OS and set release variable
release=$(uname | tr '[:upper:]' '[:lower:]')

echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && exit 1 ;;
    esac
}

echo "arch: $(arch)"

install_base() {
    case "${release}" in
    freebsd)
        # 安装依赖到用户目录
        mkdir -p ~/my_bin
        export PATH=~/my_bin:$PATH
        if ! command -v wget &> /dev/null; then
            fetch -o ~/my_bin/wget https://ftp.gnu.org/gnu/wget/wget-latest.tar.gz
            tar -xzvf ~/my_bin/wget-latest.tar.gz -C ~/my_bin/
            chmod +x ~/my_bin/wget
        fi
        if ! command -v curl &> /dev/null; then
            fetch -o ~/my_bin/curl https://curl.se/download/curl-7.87.0.tar.gz
            tar -xzvf ~/my_bin/curl-7.87.0.tar.gz -C ~/my_bin/
            chmod +x ~/my_bin/curl
        fi
        ;;
    *)
        echo -e "${red}Unsupported system!${plain}" && exit 1
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

config_after_install() {
    echo -e "${yellow}Install/update finished! For security it's recommended to modify panel settings ${plain}"
    read -p "Would you like to customize the panel settings? (If not, random settings will be applied) [y/n]: " config_confirm
    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
        read -p "Please set up your username: " config_account
        echo -e "${yellow}Your username will be: ${config_account}${plain}"
        read -p "Please set up your password: " config_password
        echo -e "${yellow}Your password will be: ${config_password}${plain}"
        read -p "Please set up the panel port: " config_port
        echo -e "${yellow}Your panel port is: ${config_port}${plain}"
        read -p "Please set up the web base path (ip:port/webbasepath/): " config_webBasePath
        echo -e "${yellow}Your web base path is: ${config_webBasePath}${plain}"
        echo -e "${yellow}Initializing, please wait...${plain}"
        ~/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        ~/x-ui/x-ui setting -port ${config_port}
        ~/x-ui/x-ui setting -webBasePath ${config_webBasePath}
    else
        echo -e "${red}Cancel...${plain}"
        if [[ ! -f "~/x-ui/x-ui.db" ]]; then
            local usernameTemp=$(head -c 6 /dev/urandom | base64)
            local passwordTemp=$(head -c 6 /dev/urandom | base64)
            local webBasePathTemp=$(gen_random_string 10)
            ~/x-ui/x-ui setting -username ${usernameTemp} -password ${passwordTemp} -webBasePath ${webBasePathTemp}
            echo -e "This is a fresh installation, random login info for security:"
            echo -e "${green}Username: ${usernameTemp}${plain}"
            echo -e "${green}Password: ${passwordTemp}${plain}"
            echo -e "${green}WebBasePath: ${webBasePathTemp}${plain}"
        else
            echo -e "${yellow}This is your upgrade, keeping old settings. ${plain}"
        fi
    fi
    ~/x-ui/x-ui migrate
}

install_x-ui() {
    mkdir -p ~/x-ui/
    cd ~/x-ui/

    last_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [[ ! -n "$last_version" ]]; then
        echo -e "${red}Failed to fetch x-ui version${plain}"
        exit 1
    fi
    echo -e "Got x-ui latest version: ${last_version}, beginning the installation..."

    wget -N --no-check-certificate -O ~/x-ui/x-ui-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch).tar.gz
    if [[ $? -ne 0 ]]; then
        echo -e "${red}Downloading x-ui failed. ${plain}"
        exit 1
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    chmod +x ~/x-ui/x-ui

    # 启动 x-ui
    ~/x-ui/x-ui start
    config_after_install

    echo -e "${green}x-ui ${last_version}${plain} installation finished, running now..."
    echo -e "x-ui control menu usages: "
    echo -e "x-ui start        - Start"
    echo -e "x-ui stop         - Stop"
    echo -e "x-ui restart      - Restart"
    echo -e "x-ui status       - Current Status"
    echo -e "x-ui settings     - Current Settings"
    echo -e "x-ui enable       - Enable Autostart"
    echo -e "x-ui disable      - Disable Autostart"
    echo -e "x-ui log          - Check logs"
}

echo -e "${green}Running...${plain}"
install_base
install_x-ui $1
