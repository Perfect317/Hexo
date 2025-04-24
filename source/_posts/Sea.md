---
title: Hackthebox-Sea
date: 2025-04-21 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250421160529230](./sea/image-20250421160529230.png)

## 80

![image-20250421160537019](./sea/image-20250421160537019.png)

![image-20250421172110191](./sea/image-20250421172110191.png)

尝试XSS获取cookie失败，

但是在website输入本机开放的web服务会收到请求

![image-20250421172205787](./sea/image-20250421172205787.png)

对扫出来的目录再进行扫描

![image-20250421163858238](./sea/image-20250421163858238.png)

![image-20250421164622175](./sea/image-20250421164622175.png)

![image-20250421165945781](./sea/image-20250421165945781.png)

最终在/themes/bike/下找到使用的CMS和版本号

![image-20250421170031787](./sea/image-20250421170031787.png)

![image-20250421170019890](./sea/image-20250421170019890.png)

![image-20250421170123949](./sea/image-20250421170123949.png)

```
turboblack 3.2.0
```

# Get shell

根据该CMS和版本搜索到[CVE-2023-41425 ](./https://github.com/thefizzyfish/CVE-2023-41425-wonderCMS_RCE)，存在xss漏洞

![image-20250422095035683](./Sea/image-20250422095035683.png)

将包含xss的url写入`contact.php`的`website`中，上面测试过对`website`输入框中的内容会发起http请求，等待一会即可得到shell

![image-20250422095250017](./Sea/image-20250422095250017.png)

但是该用户没有权限读取到user.txt

![image-20250422095507184](./Sea/image-20250422095507184.png)

![image-20250422110627205](./Sea/image-20250422110627205.png)

其中有两个斜杠做转义，删除斜杠使用john破解密码

```
mychemicalromance
```

![image-20250422141512558](./Sea/image-20250422141512558.png)

并且本地运行一个8080服务，通过ssh将端口转发到本地,通过浏览器打开

```
ssh -L 8082:127.0.0.1:8000 amay@10.10.11.28
```

![image-20250422141656667](./Sea/image-20250422141656667.png)

分析日志文件的时候进行抓包，此时会从服务器请求日志文件

![image-20250422142101518](./Sea/image-20250422142101518.png)修改log_file可以任意文件读取

![image-20250422142315597](./Sea/image-20250422142315597.png)

分号后面跟其他命令可以命令执行，需要以+#注释后面的内容，并且是以root权限执行，反弹shell就可以得到root的shell

![image-20250422142720718](./Sea/image-20250422142720718.png)

![image-20250422143147310](./Sea/image-20250422143147310.png)
