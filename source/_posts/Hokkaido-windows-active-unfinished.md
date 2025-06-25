---
title: Proving Grounds Practive-Hokkaido-Windows_Active
date: 2025-6-20 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---

# 信息收集

## nmap

![image-20250619150549451](./Hokkaido-windows-active/image-20250619150549451.png)

![image-20250619150611819](./Hokkaido-windows-active/image-20250619150611819.png)

![image-20250619150627605](./Hokkaido-windows-active/image-20250619150627605.png)

```
53/tcp    
80/tcp    
88/tcp    
135/tcp   
139/tcp   
389/tcp   
445/tcp   
464/tcp   
593/tcp   
636/tcp   
1433/tcp  
3268/tcp  
3269/tcp  
3389/tcp  
5985/tcp  
8530/tcp  
8531/tcp  
9389/tcp  
47001/tcp 
49664/tcp 
49665/tcp 
49666/tcp 
49667/tcp 
49668/tcp 
49671/tcp 
49675/tcp 
49684/tcp 
49685/tcp 
49691/tcp 
49700/tcp 
49701/tcp 
49712/tcp 
49785/tcp 
58538/tcp 
```

## 88端口

kerbrute用户名枚举

![image-20250619155905636](./Hokkaido-windows-active/image-20250619155905636.png)

将枚举出的用户名保存为用户和密码，使用crackmapexec爆破smb可用的账户密码，`info:info`

## smb

![image-20250619160655993](./Hokkaido-windows-active/image-20250619160655993.png)

![image-20250619160933265](./Hokkaido-windows-active/image-20250619160933265.png)

![image-20250619163449830](./Hokkaido-windows-active/image-20250619163449830.png)

![image-20250619163457565](./Hokkaido-windows-active/image-20250619163457565.png)

smb中存在初始密码，还有一堆账户的文件夹，其中都是空，但是知道了账户名，配合初始密码可以进行爆破

![image-20250619164311296](./Hokkaido-windows-active/image-20250619164311296.png)

![image-20250619165052396](./Hokkaido-windows-active/image-20250619165052396.png)

成功爆破到一个账户

```
discovery:Start123!
```

## GetUserSPNS

可以通过已知账户去AS-REP Roasting攻击，检索设置了“不需要 Kerberos 预身份验证”的域用户

![image-20250619165323252](./Hokkaido-windows-active/image-20250619165323252.png)

但是无法破解

## mssql

通过上面得到的用户去连接mssql

```
impacket-mssqlclient 'hokkaido-aerospace.com/discovery':'Start123!'@192.168.232.40 -dc-ip 192.168.232.40 -windows-auth
```

但是没有访问数据库的权限，查看登录历史，其中有一个用户名就是该数据库名，

![image-20250619170946697](./Hokkaido-windows-active/image-20250619170946697.png)

![image-20250619171005945](./Hokkaido-windows-active/image-20250619171005945.png)

以该用户执行命令去访问数据库

![image-20250619171024008](./Hokkaido-windows-active/image-20250619171024008.png)

![image-20250619170919745](./Hokkaido-windows-active/image-20250619170919745.png)

可以得到一个账号密码

```
hrapp-service:Untimed$Runny
```

## bloodhound

![image-20250619174807856](./Hokkaido-windows-active/image-20250619174807856.png)

![image-20250619174845320](./Hokkaido-windows-active/image-20250619174845320.png)

`HRAPP`对`HAZEL`用户有完全写权限，按照help中的说明使用`taretedKerberoast`脚本可以得到`HAZEL`用户密码的hash值

https://github.com/ShutdownRepo/targetedKerberoast

![image-20250619174735291](./Hokkaido-windows-active/image-20250619174735291.png)

![image-20250619174712133](./Hokkaido-windows-active/image-20250619174712133.png)

然后对hash值进行破解，就可以得到密码

```
Hazel.Green:haze1988
```

![image-20250624103744851](./Hokkaido-windows-active/image-20250624103744851.png)

按照给的wp,Hazel.Green所在的TIER2 admin组可以对molly.smith用户修改密码，而molly.smith用户有rdp权限，可以通过远程桌面连接

但是现在Hazel.Green用户无法修改molly.smith的密码了。止步于此
