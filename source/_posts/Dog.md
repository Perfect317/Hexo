---
title: HackTheBox-Dog
date: 2025-4-8 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# nmap

![image-20250408183137936](./Dog/image-20250408183137936.png)

# 80端口

存在登录页面，并且是Backdrop CMS但是不知道版本号

![image-20250409100523708](./Dog/image-20250409100523708.png)

## dirsearch

![image-20250408183153732](./Dog/image-20250408183153732.png)

## git 泄露

### Username and Password

使用githacker将git库下载到本地，尝试在git泄露中找CMS版本，账号密码

`setting.php`中有database账号密码

![image-20250409093213107](./Dog/image-20250409093213107.png)

```
mysql://root:BackDropJ2024DS2024@127.0.0.1/backdrop
```

使用grep -r 递归查找`username`,`password`,`email`,`dog.htb`,`version`

登录方式还有email登录，搜索email的时候有example.com，在先前的靶机中也有类似的操作，所以搜索dog.htb可以查到账号信息

![image-20250409100707572](./Dog/image-20250409100707572.png)

```
tiffany@dog.htb
```

使用该账号和数据库的密码即可登录

### Version

版本号可以在modules，themes中找到

![image-20250409101251723](./Dog/image-20250409101251723.png)

该版本存在经过身份验证的远程命令执行

[LGenAgul/Backdrop-CMS-Version-1.27.1-Authenticated-Remote-Code-Execution：](./https://github.com/LGenAgul/Backdrop-CMS-Version-1.27.1-Authenticated-Remote-Code-Execution)

![image-20250409102551123](./Dog/image-20250409102551123.png)

![image-20250409102615194](./Dog/image-20250409102615194.png)

## getshell

利用命令执行可以反弹shell

![image-20250409103220774](./Dog/image-20250409103220774.png)

在home目录下发现其他两个用户，尝试使用数据库的密码进行登录，johncusack可以成功登录

![image-20250409104111343](./Dog/image-20250409104111343.png)

### 提权

有bee工具的sudo权限，bee工具--root选项是选择Backdrop安装的目录

![image-20250409104557803](./Dog/image-20250409104557803.png)

可用的命令有eval，执行的是php代码，要运行系统命令要使用system函数

![image-20250409104610005](./Dog/image-20250409104610005.png)

![image-20250409105532126](./Dog/image-20250409105532126.png)