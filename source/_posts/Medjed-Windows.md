---
title: Proving Grounds Practice-Medjed-Windows
date: 2025-6-30 20:00:00
tags: 红队
categories: 红队打靶-Windows
---

# 信息收集

## nmap

![image-20250630164411692](./Medjed-Windows/image-20250630164411692.png)

![image-20250701103139989](./Medjed-Windows/image-20250701103139989.png)

## 8000端口

访问时会跳出初始配置页面，需要配置管理员账号密码

![image-20250630164752524](./Medjed-Windows/image-20250630164752524.png)

文件服务器下可以访问C盘和D盘的文件，并且是可读可写，可以尝试写入后门

![image-20250630173458647](./Medjed-Windows/image-20250630173458647.png)

![image-20250630173510752](./Medjed-Windows/image-20250630173510752.png)

尝试了一下可以直接读取两个flag，但学习期间还是要尝试拿到shell

开放的45332也是web服务，并且是php语言开发的

![image-20250701105818144](./Medjed-Windows/image-20250701105818144.png)

![image-20250701104715197](./Medjed-Windows/image-20250701104715197.png)

![image-20250701104724269](./Medjed-Windows/image-20250701104724269.png)

这个文件夹可以解析php代码，上传一个php后门到该目录下

![image-20250701105242552](./Medjed-Windows/image-20250701105242552.png)

# 提权

获取shell的时候根据cms的版本号查询过相关漏洞

![image-20250701111015004](./Medjed-Windows/image-20250701111015004.png)

6.5版本存在本地提权漏洞

https://www.exploit-db.com/exploits/48789

![image-20250701111058093](./Medjed-Windows/image-20250701111058093.png)

漏洞原理就是允许本地低权限攻击者通过替换bd.exe将权限升级到管理员，开机会自动启动bd.exe

kali上生成exe的后门，将靶机上原有的bd.exe改名，然后将后门上传至C:\bd文件夹下，命名为bd.exe，可以通过之前的文件上传的网页上传，也可以使用powershell上传

然后重启计算机

![image-20250701112303433](./Medjed-Windows/image-20250701112303433.png)

![image-20250701111533701](./Medjed-Windows/image-20250701111533701.png)

![image-20250701112248584](./Medjed-Windows/image-20250701112248584.png)

![image-20250701112255277](./Medjed-Windows/image-20250701112255277.png)
