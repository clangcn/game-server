Game-Server
===========

[koolshare](http://koolshare.cn/forum-72-1.html)的[小宝](http://koolshare.cn/space-uid-2380.html) 宝大开发的游戏系列服务器（SS），支持udp in udp和udp in tcp模式，完美支持游戏NAT2。

脚本是业余爱好，英文属于文盲，写的不好，不要笑话我，欢迎您批评指正。
安装平台：CentOS、Debian、Ubuntu。
Server
------

### Install

Debian / Ubuntu:

    apt-get -y install screen
    screen -S game-server
    wget --no-check-certificate https://github.com/clangcn/game-server/raw/master/install-game-server.sh -O /root/install-game-server.sh
    chmod 500 /root/install-game-server.sh
    /root/install-game-server.sh

CentOS:

    yum -y install screen
    screen -S game-server
    wget --no-check-certificate https://github.com/clangcn/game-server/raw/master/install-game-server.sh -O /root/install-game-server.sh
    chmod 500 /root/install-game-server.sh
    /root/install-game-server.sh

### 服务器管理

    Usage: /etc/init.d/game-server {start|stop|restart|status}
