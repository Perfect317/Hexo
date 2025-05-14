---
title: Hackthebox-nibbles
date: 2025-05-08 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



## nmap

![image-20250508105122300](./Nibbles/image-20250508105122300.png)

## 80端口

源码下给出了其他目录

![image-20250508115850900](./Nibbles/image-20250508115850900.png)

然后对/nibbleblog进行目录扫描，发现admin.php的登录页面，update.php和README中都有版本号：`Nibbleblog 4.0.3`，搜索对应的漏洞发现任意文件上传，并且是一个msf脚本

![image-20250508113305052](./Nibbles/image-20250508113305052.png)

![image-20250508113232309](./Nibbles/image-20250508113232309.png)

直接在msf中使用，需要账号密码

![image-20250508114853627](./Nibbles/image-20250508114853627.png)

content目录下记录了admin账号的登录情况，在截图之前已经有尝试过一次

![image-20250508120210796](./Nibbles/image-20250508120210796.png)

猜测密码为nibbles,可以成功登录



![image-20250508120332895](./Nibbles/image-20250508120332895.png)

然后配置msf的参数，需要设置网站更目录，账号密码，网站ip，监听ip，成功之后就会得到nibbles用户的shell![image-20250508114843482](./Nibbles/image-20250508114843482.png)

## 提权

该用户有执行一个.sh脚本的sudo权限，但是发现该目录需要解压后才存在，那就直接手动创建一个这样的目录和文件，在monitor.sh中写入反弹shell的脚本

![image-20250508115637219](./Nibbles/image-20250508115637219.png)

![image-20250508115748064](./Nibbles/image-20250508115748064.png)

以sudo权限运行该脚本就可以成功反弹到root的shell

![image-20250508115831011](./Nibbles/image-20250508115831011.png)