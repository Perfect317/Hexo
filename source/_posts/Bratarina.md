---
title: Proving Grounds Practice-Bratarina
date: 2025-6-03 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



# 信息收集

## nmap

![image-20250603111622886](./Bratarina/image-20250603111622886.png)

## web

80端口扫目录也没有有用信息

![image-20250603135128507](./Bratarina/image-20250603135128507.png)

## smb

![image-20250603135058996](./Bratarina/image-20250603135058996.png)

![image-20250603135106460](./Bratarina/image-20250603135106460.png)

## 组件

收集到一些相关组件的版本信息，可以搜索相关漏洞

openSSH 7.6

opensmtpd

nginx 1.14.0

smbd 4.7.6

# opensmtpd-远程代码执行

![image-20250603134636087](./Bratarina/image-20250603134636087.png)

![image-20250603134540105](./Bratarina/image-20250603134540105.png)