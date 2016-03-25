Game-Server
===========

##[koolshare](http://koolshare.cn/forum-72-1.html)的[小宝](http://koolshare.cn/space-uid-2380.html) 宝大开发的游戏系列服务器（SS），支持udp in udp和udp in tcp模式，完美支持游戏NAT2。

脚本是业余爱好，英文属于文盲，写的不好，不要笑话我，欢迎您批评指正。
安装平台：CentOS、Debian、Ubuntu。
Server
------

### Install

Debian / Ubuntu:

    wget --no-check-certificate https://github.com/clangcn/game-server/raw/master/install-game-server.sh -O ./install-game-server.sh
    chmod 500 ./install-game-server.sh
    ./install-game-server.sh install

CentOS:

    wget --no-check-certificate https://github.com/clangcn/game-server/raw/master/install-game-server.sh -O ./install-game-server.sh
    chmod 500 ./install-game-server.sh
    ./install-game-server.sh install

### UnInstall

    ./install-game-server.sh uninstall

### Update

    ./install-game-server.sh update

### 服务器管理

    Usage: /etc/init.d/game-server {start|stop|restart|status}

### 多用户配置文件范例，按照下面格式修改默认的/usr/local/game-server/config.json文件：

    {
        "server":"0.0.0.0",
        "local_port":1080,
        "timeout": 600,
        "method":"chacha20",
        "port_password":
        {
            "8339": "abcd1234",
            "8340": "Clang.cn"
        },
        "_comment":
        {
            "8339": "hanleilei",
            "8340": "me"
        }
    }
