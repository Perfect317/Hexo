---
title: HackTheBox-Sauna-Windows_Active
date: 2025-04-24 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---

# 信息收集

## nmap

![image-20250424102106717](./Sauna-Windows-Active/image-20250424102106717.png)

## 80端口

![image-20250424112543256](./Sauna-Windows-Active/image-20250424112543256.png)

得到一些用户名，保存下来后面用于爆破

## ldap

```
ldapsearch -H ldap://10.10.10.175:389 -x -b "dc=EGOTISTICAL-BANK,dc=LOCAL"
```

![image-20250424112507729](./Sauna-Windows-Active/image-20250424112507729.png)

保存可疑的用户名用于后面爆破

## SMB and RPC

SMB和RPC枚举均无信息

## AS-REP Roasting攻击

### 攻击原理

要求用户账户不开启`kerberos`身份验证，此选项的作用是防止密码离线爆破，默认情况下，该选项开启，KDC会记录密码错误次数，防止在线爆破。当关闭之后，攻击者可以请求票据，此时域控不会进行任何验证就返回TGT和密码的hash，然后就可以爆破该hash

### 进行攻击

使用`kerbrute_linux_amd64`枚举的用户名都是无效的，最终使用seclists中的`xato-net-10-million-usernames.txt`字典枚举到Fsmith，发现是将上面名字的首字母和后面半部分组合形成的密码，按照此规律整合一下user字典

![image-20250424113031417](./Sauna-Windows-Active/image-20250424113031417.png)

然后使用`kerbrute_linux_amd64`枚举不需要`Kerberos`认证的用户

![image-20250424112749989](./Sauna-Windows-Active/image-20250424112749989.png)

![image-20250424112357613](./Sauna-Windows-Active/image-20250424112357613.png)

```
hashcat 破解密码
 hashcat -m 18200 -a0 password /usr/share/wordlists/rockyou.txt
```

![image-20250424114821526](./Sauna-Windows-Active/image-20250424114821526.png)

```
Fsmith:Thestrokes23
```

5985端口开启，使用evil-winrm连接

![image-20250424115416232](./Sauna-Windows-Active/image-20250424115416232.png)

## 提权

winPEASS.exe搜索可能的本地权限提升路径，其中有svc_loanmgr用户的密码

![image-20250424140014442](./Sauna-Windows-Active/image-20250424140014442.png)

![image-20250424140002599](./Sauna-Windows-Active/image-20250424140002599.png)

```
svc_loanmgr:Moneymakestheworldgoround!
```

远程连接到svc_loanmgr用户，使用SharpHound.exe检索域信息，导入Bloodhound分析

查找具有DCsync权限的机器，有svc_loanmgr，可以使用DCsync攻击

![image-20250424161805453](./Sauna-Windows-Active/image-20250424161805453.png)

导出密码的hash值然后使用hash进行远程连接到Administrator

![image-20250424155530290](./Sauna-Windows-Active/image-20250424155530290.png)

![image-20250424155925322](./Sauna-Windows-Active/image-20250424155925322.png)