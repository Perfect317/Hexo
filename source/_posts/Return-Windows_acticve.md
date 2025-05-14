---
title: HackTheBox-Return-Windows_Active
date: 2025-05-09 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---



## nmap

![image-20250509140930160](./Return-Windows_acticve/image-20250509140930160.png)

## 80端口

setting页面下可以修改ldap相关内容，提交post请求发现只会提交一个ip，将ip改为攻击机ip

![image-20250509143112755](./Return-Windows_acticve/image-20250509143112755.png)

并且打开Wireshark可以抓到包，有一个账号和简单认证的密码

![image-20250509143029767](./Return-Windows_acticve/image-20250509143029767.png)

![image-20250509143035068](./Return-Windows_acticve/image-20250509143035068.png)

使用该账号可以直接远程连接

![image-20250509144536827](./Return-Windows_acticve/image-20250509144536827.png)

## 提权

该账号有服务操作权限，可以修改服务运行情况

![image-20250509152813996](./Return-Windows_acticve/image-20250509152813996.png)

上传nc.exe，然后创建一个服务运行nc反向连接攻击机

![image-20250509152830305](./Return-Windows_acticve/image-20250509152830305.png)

![image-20250509152851562](./Return-Windows_acticve/image-20250509152851562.png)