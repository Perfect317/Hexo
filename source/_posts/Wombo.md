---
title: Proving Grounds Practice-Wombo
date: 2025-7-16 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250716103112012](./Wombo/image-20250716103112012.png)

# redis

redis可以未授权登录，并且可以访问信息，可以看到redis的版本为5.0.9

![image-20250716113517812](./Wombo/image-20250716113517812.png)

直接利用一个exp就可以得到root权限

[Ridter/redis-rce: Redis 4.x/5.x 远程代码执行 --- Ridter/redis-rce: Redis 4.x/5.x RCE](./https://github.com/Ridter/redis-rce)

mod.so文件地址：[n0b0dyCN/redis-rogue-server: Redis(<=5.0.5) RCE --- n0b0dyCN/redis-rogue-server: Redis(<=5.0.5) RCE](./https://github.com/n0b0dyCN/redis-rogue-server)

![image-20250716113947314](./Wombo/image-20250716113947314.png)

![image-20250716113952486](./Wombo/image-20250716113952486.png)