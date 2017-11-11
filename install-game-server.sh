#! /bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#===============================================================================================
#   System Required:  CentOS Debian or Ubuntu (32bit/64bit)
#   Description:  Install Game-Server(XiaoBao) for CentOS Debian or Ubuntu
#   Author: Clang <admin@clangcn.com>
#   Intro:  http://clang.cn
#===============================================================================================
version="7.3"
str_game_dir="/usr/local/game-server"
game_x64_download_url=https://raw.githubusercontent.com/clangcn/game-server/master/latest/game-server
game_x86_download_url=https://raw.githubusercontent.com/clangcn/game-server/master/latest/game-server-386
program_init_download_url=https://raw.githubusercontent.com/clangcn/game-server/master/init/game-server.init
str_install_shell=https://raw.githubusercontent.com/clangcn/game-server/master/install-game-server.sh
shell_update(){
    clear
    fun_clang.cn
    echo "Check updates for shell..."
    remote_shell_version=`wget --no-check-certificate -qO- ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
    if [ ! -z ${remote_shell_version} ]; then
        if [[ "${version}" != "${remote_shell_version}" ]];then
            echo -e "${COLOR_GREEN}Found a new version,update now!!!${COLOR_END}"
            echo
            echo -n "Update shell ..."
            if ! wget --no-check-certificate -qO $0 ${str_install_shell}; then
                echo -e " [${COLOR_RED}failed${COLOR_END}]"
                echo
                exit 1
            else
                echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
                echo
                echo -e "${COLOR_GREEN}Please Re-run${COLOR_END} ${COLOR_PINK}$0 ${clang_action}${COLOR_END}"
                echo
                exit 1
            fi
            exit 1
        fi
    fi
}
fun_clang.cn(){
    echo ""
    echo "#####################################################################"
    echo "# Install Game-Server(XiaoBao) for CentOS Debian or Ubuntu(32/64bit)"
    echo "# Version ${version}"
    echo "#####################################################################"
    echo ""
}

# Check if user is root
rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_clang.cn
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}

get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
}

fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_CYAN_BLUE='\033[40;36m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_END='\E[0m'
}

# Check OS
checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi
}

# CentOS version
centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi
}

# Check OS bit
check_os_bit(){
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}

check_centosversion(){
if centosversion 5; then
    echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
    exit 1
fi
}

# Disable selinux
disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

# Check port
fun_check_port(){
    strServerPort="$1"
    if [ ${strServerPort} -ge 1 ] && [ ${strServerPort} -le 65535 ]; then
        checkServerPort=`netstat -ntul | grep "\b:${strServerPort}\b"`
        if [ -n "${checkServerPort}" ]; then
            echo ""
            echo -e "${COLOR_RED}Error:${COLOR_END} Port ${COLOR_GREEN}${strServerPort}${COLOR_END} is ${COLOR_PINK}mused${COLOR_END},view relevant port:"
            #netstat -apn | grep "\b:${strServerPort}\b"
            netstat -ntulp | grep "\b:${strServerPort}\b"
            fun_input_port
        else
            serverport="${strServerPort}"
        fi
    else
        echo "Input error! Please input correct numbers."
        fun_input_port
    fi
}

# input port
fun_input_port(){
    server_port="8838"
    echo ""
    echo -e "Please input Server Port [1-65535](Don't the same SSH Port ${COLOR_RED}${sshport}${COLOR_END})"
    read -p "(Default Server Port: ${server_port}):" serverport
    [ -z "${serverport}" ] && serverport="${server_port}"
    fun_check_port "${serverport}"
}

# Random password
fun_randstr(){
  index=0
  strRandomPass=""
  for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {1..16}; do strRandomPass="$strRandomPass${arr[$RANDOM%$index]}"; done
  echo $strRandomPass
}
# ====== check packs ======
pre_install_packs(){
    local wget_flag=''
    local killall_flag=''
    local netstat_flag=''
    local curl_flag=''
    local iptables_flag=''
    local vim_flag=''
    wget --version > /dev/null 2>&1
    wget_flag=$?
    killall -V >/dev/null 2>&1
    killall_flag=$?
    netstat --version >/dev/null 2>&1
    netstat_flag=$?
    curl -V > /dev/null 2>&1
    curl_flag=$?
    iptables -V > /dev/null 2>&1
    iptables_flag=$?
    vim --version > /dev/null 2>&1
    vim_flag=$?
    if [[ ${wget_flag} -gt 1 ]] || [[ ${killall_flag} -gt 1 ]] || [[ ${netstat_flag} -gt 6 ]] || [[ ${curl_flag} -gt 1 ]] || [[ ${iptables_flag} -gt 1 ]] || [[ ${vim_flag} -gt 1 ]];then
        echo -e "${COLOR_GREEN} Install support packs...${COLOR_END}"
        if [ "${OS}" == 'CentOS' ]; then
            yum install -y wget psmisc net-tools curl-devel iptables policycoreutils libpcap libpcap-devel vim
        else
            apt-get -y update && apt-get -y install wget psmisc net-tools curl iptables libpcap-dev vim
        fi
    fi
}

# ====== pre_install ======
pre_install_clang(){
    #config setting
    echo " Please input your Game-Server(XiaoBao) server_port and password"
    echo ""
    sshport=`netstat -anp |grep ssh | grep '0.0.0.0:'|cut -d: -f2| awk 'NR==1 { print $1}'`
    #defIP=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.' | cut -d: -f2 | awk 'NR==1 { print $1}'`
    #if [ "${defIP}" = "" ]; then
        defIP=$(curl -s -4 ip.clang.cn)
    #fi
    IP="0.0.0.0"
    echo "You VPS IP:$defIP"
    fun_input_port
    echo ""
    shadowsocks_pwd=`fun_randstr`
    read -p "Please input Password (Default Password: ${shadowsocks_pwd}):" shadowsockspwd
    if [ "${shadowsockspwd}" = "" ]; then
        shadowsockspwd="${shadowsocks_pwd}"
    fi
    echo ""
    ssmethod="chacha20"
    echo "Please input Encryption method(chacha20-ietf, chacha20, aes-256-cfb, bf-cfb, des-cfb, rc4)"
    read -p "(Default method: ${ssmethod}):" ssmethod
    if [ "${ssmethod}" = "" ]; then
        ssmethod="chacha20"
    fi
    echo ""
    set_iptables="n"
        echo  -e "${COLOR_YELOW}Do you want to set iptables?${COLOR_END}"
        read -p "(if you want please input: y,Default [no]):" set_iptables

        case "${set_iptables}" in
        y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
        echo "You will set iptables!"
        set_iptables="y"
        ;;
        n|N|No|NO|no|nO)
        echo "You will NOT set iptables!"
        set_iptables="n"
        ;;
        *)
        echo "The iptables is not set!"
        set_iptables="n"
        esac

    echo ""
    echo "============== Check your input =============="
    echo -e "Your Server IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo -e "Your Server Port:${COLOR_GREEN}${serverport}${COLOR_END}"
    echo -e "Your Password:${COLOR_GREEN}${shadowsockspwd}${COLOR_END}"
    echo -e "Your Encryption Method:${COLOR_GREEN}${ssmethod}${COLOR_END}"
    echo -e "Your SSH Port:${COLOR_GREEN}${sshport}${COLOR_END}"
    echo "=============================================="
    echo ""
    echo "Press any key to start...or Press Ctrl+c to cancel"

    char=`get_char`

    [ ! -d ${str_game_dir} ] && mkdir -p ${str_game_dir}
    cd ${str_game_dir}
    echo $PWD

# Config shadowsocks
cat > ${str_game_dir}/config.json<<-EOF
{
    "server":"${IP}",
    "local_port":1080,
    "timeout": 600,
    "method":"${ssmethod}",
    "fast_open": true,
    "port_password":
    {
        "${serverport}": "${shadowsockspwd}"
    },
    "_comment":
    {
        "${serverport}": "The server port comment"
    }
}
EOF
    chmod 600 ${str_game_dir}/config.json
    rm -f ${str_game_dir}/game-server
    if [ "${Is_64bit}" == 'y' ] ; then
        if [ ! -s ${str_game_dir}/game-server ]; then
            if ! wget --no-check-certificate ${game_x64_download_url} -O ${str_game_dir}/game-server; then
                echo "Failed to download game-server file!"
                exit 1
            fi
        fi
    else
         if [ ! -s ${str_game_dir}/game-server ]; then
            if ! wget --no-check-certificate ${game_x86_download_url} -O ${str_game_dir}/game-server; then
                echo "Failed to download game-server file!"
                exit 1
            fi
        fi
    fi
    [ ! -x ${str_game_dir}/game-server ] && chmod 755 ${str_game_dir}/game-server
    if [ ! -s /etc/init.d/game-server ]; then
        if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/game-server; then
            echo "Failed to download game-server.init file!"
            exit 1
        fi
    fi
    [ ! -x /etc/init.d/game-server ] && chmod +x /etc/init.d/game-server
    if [ "${OS}" == 'CentOS' ]; then
        chmod +x /etc/init.d/game-server
        chkconfig --add game-server
    else
        chmod +x /etc/init.d/game-server
        update-rc.d -f game-server defaults
    fi

    if [ "$set_iptables" == 'y' ]; then
        # iptables config
        iptables -I INPUT -p udp --dport ${serverport} -j ACCEPT
        iptables -I INPUT -p tcp --dport ${serverport} -j ACCEPT
        iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
        if [ "${OS}" == 'CentOS' ]; then
            service iptables save
        else
            echo '#!/bin/bash' > /etc/network/if-post-down.d/iptables
            echo 'iptables-save > /etc/iptables.rules' >> /etc/network/if-post-down.d/iptables
            echo 'exit 0;' >> /etc/network/if-post-down.d/iptables
            chmod +x /etc/network/if-post-down.d/iptables

            echo '#!/bin/bash' > /etc/network/if-pre-up.d/iptables
            echo 'iptables-restore < /etc/iptables.rules' >> /etc/network/if-pre-up.d/iptables
            echo 'exit 0;' >> /etc/network/if-pre-up.d/iptables
            chmod +x /etc/network/if-pre-up.d/iptables
        fi
    fi
    [ -s /etc/init.d/game-server ] && ln -s /etc/init.d/game-server /usr/bin/game-server
    /etc/init.d/game-server start
    ${str_game_dir}/game-server -version
    echo ""
    fun_clang.cn
    #install successfully
    echo ""
    echo "Congratulations, Game-Server(XiaoBao) install completed!"
    echo -e "Your Server IP:${COLOR_GREEN}${defIP}${COLOR_END}"
    echo -e "Your Set IP:${COLOR_GREEN}${IP}${COLOR_END}"
    echo -e "Your Server Port:${COLOR_GREEN}${serverport}${COLOR_END}"
    echo -e "Your Password:${COLOR_GREEN}${shadowsockspwd}${COLOR_END}"
    echo -e "Your Local Port:${COLOR_GREEN}1080${COLOR_END}"
    echo -e "Your Encryption Method:${COLOR_GREEN}${ssmethod}${COLOR_END}"
    echo ""
    echo -e "Game-Server(XiaoBao) status manage: ${COLOR_PINKBACK_WHITEFONT}/etc/init.d/game-server${COLOR_END} {${COLOR_PINK}start${COLOR_END}|${COLOR_GREEN}stop${COLOR_END}|${COLOR_YELOW}restart${COLOR_END}|${COLOR_CYAN_BLUE}status${COLOR_END}}"
    #iptables -L -n
}
############################### install function ##################################
install_game_server_clang(){
    fun_clang.cn
    checkos
    check_centosversion
    check_os_bit
    disable_selinux
    if [ -s ${str_game_dir}/game-server ] && [ -s /etc/init.d/game-server ]; then
        echo "Game-Server(XiaoBao) is installed!"
    else
        pre_install_clang
    fi
}
############################### configure function ##################################
configure_game_server_clang(){
    if [ -s ${str_game_dir}/config.json ]; then
        vim ${str_game_dir}/config.json
    else
        echo "Game-Server(XiaoBao) configuration file not found!"
    fi
}
############################### uninstall function ##################################
uninstall_game_server_clang(){
    fun_clang.cn
    if [ -s /etc/init.d/game-server ] || [ -s ${str_game_dir}/game-server ] ; then
        echo "============== Uninstall Game-Server(XiaoBao) =============="
        save_config="n"
        echo  -e "${COLOR_YELOW}Do you want to keep the configuration file?${COLOR_END}"
        read -p "(if you want please input: y,Default [no]):" save_config

        case "${save_config}" in
        y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
        echo ""
        echo "You will keep the configuration file!"
        save_config="y"
        ;;
        n|N|No|NO|no|nO)
        echo ""
        echo "You will NOT to keep the configuration file!"
        save_config="n"
        ;;
        *)
        echo ""
        echo "will NOT to keep the configuration file!"
        save_config="n"
        esac
        checkos
        /etc/init.d/game-server stop
        if [ "${OS}" == 'CentOS' ]; then
            chkconfig --del game-server
        else
            update-rc.d -f game-server remove
        fi
        rm -f /usr/bin/game-server /etc/init.d/game-server /var/run/game-server.pid /root/game-server-install.log /root/game-server-update.log
        if [ "${save_config}" == 'n' ]; then
            rm -fr ${str_game_dir}
        else
            rm -f ${str_game_dir}/game-server ${str_game_dir}/game-server.log
        fi
        echo "Game-Server(XiaoBao) uninstall success!"
    else
        echo "Game-Server(XiaoBao) Not install!"
    fi
    echo ""
}
############################### update function ##################################
update_game_server_clang(){
    fun_clang.cn
    if [ -s /etc/init.d/game-server ] || [ -s ${str_game_dir}/game-server ] ; then
        echo "============== Update Game-Server(XiaoBao) =============="
        checkos
        check_centosversion
        check_os_bit
        killall game-server
        remote_init_version=`wget --no-check-certificate -qO- ${program_init_download_url} | sed -n '/'^version'/p' | cut -d\" -f2`
        local_init_version=`sed -n '/'^version'/p' /etc/init.d/game-server | cut -d\" -f2`
        if [ ! -z ${remote_init_version} ];then
            if [[ "${local_init_version}" != "${remote_init_version}" ]];then
                echo "========== Update Game-Server(XiaoBao) /etc/init.d/game-server =========="
                if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/game-server; then
                    echo "Failed to download game-server.init file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}/etc/init.d/game-server Update successfully !!!${COLOR_END}"
                fi
            fi
        fi
        [ ! -d ${str_game_dir} ] && mkdir -p ${str_game_dir}
        rm -f /usr/bin/game-server ${str_game_dir}/game-server /root/game-server /root/game-server.log
        if [ "${Is_64bit}" == 'y' ] ; then
            if ! wget --no-check-certificate ${game_x64_download_url} -O ${str_game_dir}/game-server; then
                echo "Failed to download game-server file!"
                exit 1
            fi
        else
            if ! wget --no-check-certificate ${game_x86_download_url} -O ${str_game_dir}/game-server; then
                echo "Failed to download game-server file!"
                exit 1
            fi
        fi
        [ ! -x ${str_game_dir}/game-server ] && chmod 755 ${str_game_dir}/game-server
        if [ "${OS}" == 'CentOS' ]; then
            chmod +x /etc/init.d/game-server
            chkconfig --add game-server
        else
            chmod +x /etc/init.d/game-server
            update-rc.d -f game-server defaults
        fi
        [ -s /etc/init.d/game-server ] && ln -s /etc/init.d/game-server /usr/bin/game-server
        if [ -s /root/config.json ] && [ ! -a ${str_game_dir}/config.json ]; then
            mv /root/config.json ${str_game_dir}/config.json
        fi
        /etc/init.d/game-server start
        ${str_game_dir}/game-server -version
        echo "Game-Server(XiaoBao) update success!"
    else
        echo "Game-Server(XiaoBao) Not install!"
    fi
    echo ""
}
clear
rootness
strPath=`pwd`
pre_install_packs
shell_update
# Initialization
action=$1
[  -z $1 ]
case "$action" in
install)
    install_game_server_clang 2>&1 | tee /root/game-server-install.log
    ;;
config)
    configure_game_server_clang
    ;;
uninstall)
    uninstall_game_server_clang 2>&1 | tee /root/game-server-uninstall.log
    ;;
update)
    update_game_server_clang 2>&1 | tee /root/game-server-update.log
    ;;
*)
    fun_clang.cn
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update|config}"
    ;;
esac
