---
title: Proving Grounds Practice-apex
date: 2025-6-24 20:00:00
tags: 红队
categories: 红队打靶-Linux

---

# 信息收集

## nmap

![image-20250624151117788](./apex/image-20250624151117788.png)

## 80端口-web

可以对以下路径扫目录，可以扫到很多内容，但是好多都是无法访问的，

openemr/interface目录是通过主页面下的登录界面知道的路径

> http://ip/
>
> http://ip/openemr/
>
> http://ip/openemr/interface



![image-20250624162834641](./apex/image-20250624162834641.png)

## smb

![image-20250624162218508](./apex/image-20250624162218508.png)

![image-20250624162355174](./apex/image-20250624162355174.png)

# exploit

smb中的文件正好是filemanager目录下的文件，这个页面访问的很慢，通过官方给的web端的kali访问也很慢，并且根据wp中的访问右上角的问号可以查看版本号也不太行，只能根据wp中已经给出的版本号继续做了，这个文件管理系统的版本号是9.13.4

![image-20250624162436731](./apex/image-20250624162436731.png)

该版本存在任意文件读取漏洞，修改cookie和url地址就可以成功读取文件



https://www.exploit-db.com/exploits/45987

![image-20250624165026626](./apex/image-20250624165026626.png)

通过其中的第一个payload只能读取部分文件，比如读取`/openemr/interface/main/backuplog.sh`文件时，就会报错提示权限不足，这个文件时访问web界面时可以读取的文件，其他php文件不可以读取

绝对路径路径也很容易猜测`var/www/openemr/interface/main/backuplog.sh`

![/openemr/interface/main/backuplog.sh](./apex/image-20250624175529775.png)

```
curl -X POST -d "path=../../../../../../../var/www/openemr/interface/main/backuplog.sh" -H "Cookie: PHPSESSID=30740g3d5mgv1l1lbj3eldup6o" "http://192.168.219.145/filemanager/ajax_calls.php?action=get_file&sub_action=edit&preview_mode=text"
```

![image-20250624175412133](./apex/image-20250624175412133.png)



尝试寻找其他exp

https://www.exploit-db.com/exploits/49359

![image-20250625094925610](./apex/image-20250625094925610.png)

通过github上的源码，可以找到数据库的配置文件在sites/default/sqlconf.php下

该exp是粘贴在默认目录下，可以将目录改为之前发现的smb目录下，这样做的目的是文件读取的时候对后缀名进行了限制，比如`sqlconf.php`通过exp是无法直接读取的，所以将文件写到smb下，可以通过smb来读取

![image-20250625105342706](./apex/image-20250625105342706.png)

![image-20250625105806449](./apex/image-20250625105806449.png)

运行exp之后也是成功将php文件写到了smb下

![image-20250625105938519](./apex/image-20250625105938519.png)

![image-20250625105932889](./apex/image-20250625105932889.png)

sql配置文件夹下有数据库连接账号密码

![image-20250625110243832](./apex/image-20250625110243832.png)

```
openemr:C78maEQUIEuQ
```

```
 mysql -h 192.168.133.145 -P 3306 -u openemr -p --skip-ssl-verify-server-cert
```

![image-20250625111245264](./apex/image-20250625111245264.png)

```
数据库操作
SHOW DATABASES;
use openemr;
SHOW TABLES;
select * from users;
```

![image-20250625111858051](./apex/image-20250625111858051.png)

```
admin:NoLongerUsed 
phimail-service:NoLogin
portal-user:NoLogin     
```

这里有坑，正确密码应该是在`users_secure`表下，查询得到加密方式，然后使用hashcat指定加密方式去破解

![image-20250625112242085](./apex/image-20250625112242085.png)

![image-20250625114017802](./apex/image-20250625114017802.png)

![image-20250625114056409](./apex/image-20250625114056409.png)

```
admin:thedoctor
```

# 成功登录openemr

使用上述账号密码就可以成功登录到openemr的后台。about选项卡中有openemr的版本号

![image-20250625114446406](./apex/image-20250625114446406.png)

https://www.exploit-db.com/exploits/45161

查找该版本存在的漏洞，存在经过验证的远程代码执行，通过该exp可以成功得到shell

![image-20250625142016327](./apex/image-20250625142016327.png)

# 提权

可以使用PwnKit漏洞

![image-20250625144108991](./apex/image-20250625144108991.png)

之前找到的admin的密码thedocter就是root的密码也可以通过密码提权