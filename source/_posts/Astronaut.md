---
title: Proving Grounds Practice-Astronaut
date: 2025-7-05 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250705133323152](./Astronaut/image-20250705133323152.png)

# 80端口-getshell

80端口是个grav cms，该cms多个版本都有漏洞，我想尝试找到版本号之后再利用漏洞，找了半天也没找到版本号，看了wp也是直接就利用漏洞了，还请高人指点。

![image-20250705205036685](./Astronaut/image-20250705205036685.png)

直接使用msf利用这个漏洞即可反弹shell

![image-20250705205103230](./Astronaut/image-20250705205103230.png)

# 提权

SUID提权，其中的php可以利用

![image-20250706101131807](./Astronaut/image-20250706101131807.png)

![image-20250706101147898](./Astronaut/image-20250706101147898.png)

![image-20250706101207436](./Astronaut/image-20250706101207436.png)