---
title: Proving Grounds Practice-PC
date: 2025-6-24 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



# 信息收集

## nmap

![image-20250624112508341](./PC/image-20250624112508341.png)

## 8000端口

8000端口直接就是一个shell，反弹到本地，然后进行提权

![image-20250624112522764](./PC/image-20250624112522764.png)

# 提权

![image-20250624141752224](./PC/image-20250624141752224.png)

![image-20250624141801154](./PC/image-20250624141801154.png)

![image-20250624141817110](./PC/image-20250624141817110.png)

搜索`rpc.py exp` ,CVE-2022-35411 漏洞可以远程代码执行，该进程是以root权限运行，命令执行也是以root权限，反弹shell就可以拿到root权限

![image-20250624145241477](./PC/image-20250624145241477.png)