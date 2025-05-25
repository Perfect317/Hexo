---
title: Proving Grounds Practice-ClamAV
date: 2025-5-25 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

## nmap

![image-20250525165929745](./ClamAV/image-20250525165929745.png)

## web

![image-20250525183212292](./ClamAV/image-20250525183212292.png)

![image-20250525172542128](./ClamAV/image-20250525172542128.png)

没看明白到底是什么意思

```
if you dont pwnmeur a n00b
```

## exploit利用

使用searchsploit搜索clamav

![image-20250525183327587](./ClamAV/image-20250525183327587.png)

存在远程代码执行漏洞，使用perl执行，打开了31337端口，并且是root权限，直接使用nc连接即可

![image-20250525183412057](./ClamAV/image-20250525183412057.png)

proving-grounds打的第一个靶机，比较简单，主要是配置了一下网络连接问题。

![image-20250525183452800](./ClamAV/image-20250525183452800.png)