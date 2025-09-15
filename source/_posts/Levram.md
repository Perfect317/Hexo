---
title: Proving Grounds Practice-Levram
date: 2025-7-18 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250718095736786](./Levram/image-20250718095736786.png)

# 8000端口

8000端口是个登录页面，使用弱密码`admin,admin`就登录成功了

![image-20250718100212597](./Levram/image-20250718100212597.png)

搜索`gerapy 0.9.7`，该版本存在经过认证的远程代码执行

[Gerapy parse 后台远程命令执行漏洞-秋刀鱼实验室](./https://www.saury.net/2148.html)

根据这篇文章对漏洞进行复现

将命令改为反向shell

![image-20250718111932148](./Levram/image-20250718111932148.png)

# 提权

python命令有capabilities机制，通过GTFObins中的方法就可以提权

![image-20250718113043307](./Levram/image-20250718113043307.png)

![image-20250718113127284](./Levram/image-20250718113127284.png)

![image-20250718113132397](./Levram/image-20250718113132397.png)