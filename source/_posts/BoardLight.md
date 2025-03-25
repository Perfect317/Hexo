---
title: HackTheBox-BoardLight
data: 2025-3-25 19:24:00
tags: 红队
categories: 红队打靶
---



## nmap

![image-20250325163143708](./././././BoardLight/image-20250325163143708.png)

## WEB

扫描目录没有什么有用的信息

扫描子域名得到一个crm.board.htb

![image-20250325181713730](./././././BoardLight/image-20250325181713730.png)

访问之后是个登录页面，有版本号为Dolibarr 17.0.0

![image-20250325181754031](./././././BoardLight/image-20250325181754031.png)

搜索相关漏洞，存在[CVE-2023-30253](./././././https://github.com/nikn0laty/Exploit-for-Dolibarr-17.0.0-CVE-2023-30253),但是是php任意命令执行，要利用还是要先登录

![image-20250325182007032](./././././BoardLight/image-20250325182007032.png)

查找[默认账号密码](./././././https://www.dolibarr.org/forum/t/login-after-installation/16088/4)，经过测试默认密码为admin:admin

![image-20250325182107767](./././././BoardLight/image-20250325182107767.png)

## 获得shell

利用[EXP](./././././https://github.com/nikn0laty/Exploit-for-Dolibarr-17.0.0-CVE-2023-30253)来反弹shell

![image-20250325183104068](./././././BoardLight/image-20250325183104068.png)

![image-20250325183109700](./././././BoardLight/image-20250325183109700.png)

在home目录下发现另外一个用户，该用户有shell权限

![image-20250325184517427](./././././BoardLight/image-20250325184517427.png)

![image-20250325184527240](./././././BoardLight/image-20250325184527240.png)



在html/crm.board.htb/htdocs/conf下有网站的配置文件，配置文件中找到了mysql远程登录账号密码

![image-20250325184340162](./././././BoardLight/image-20250325184340162.png)

`dolibarrowner:serverfun2$2023!!`

使用账号密码登录到mysql数据库

```
mysql -h127.0.0.1 -P3306 -udolibarrowner -p
```

![image-20250325190325668](./././././BoardLight/image-20250325190325668.png)

## 提权

没有查到什么有用的信息，尝试用连接数据库的密码去登录`larissa`

![image-20250325190747366](./././././BoardLight/image-20250325190747366.png)

`larissa`不能运行sudo

![image-20250325190833339](./././././BoardLight/image-20250325191840622.png)

查看suid权限的文件，enlightenment_sys存在提权漏洞[CVE-2022-37706](./././././https://github.com/MaherAzzouzi/CVE-2022-37706-LPE-exploit)

![image-20250325191848668](./././././BoardLight/image-20250325191848668.png)

将文件下载到本地上传到靶机之后直接运行即可

![image-20250325192015066](./././././BoardLight/image-20250325192015066.png)