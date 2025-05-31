---
title: Proving Grounds Practice-Kevin-Windows
date: 2025-5-27 20:00:00
tags: 红队
categories: 红队打靶-Windows
---

## nmap

![image-20250527150654558](./Kevin-Windows/image-20250527150654558.png)

## web

使用弱密码admin:admin可以登录，其中有版本信息

![image-20250527161144116](./Kevin-Windows/image-20250527161144116.png)

使用searchsploit 搜索相关漏洞，存在缓冲区溢出漏洞

![image-20250527161247482](./Kevin-Windows/image-20250527161247482.png)



利用该漏洞即可得到shell

