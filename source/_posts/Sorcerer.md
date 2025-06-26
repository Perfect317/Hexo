---
title: Proving Grounds Practice-Sorcerer
date: 2025-6-26 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## mmap

![image-20250626142754485](./Sorcerer/image-20250626142754485.png)

# web服务

## 7742端口

![image-20250626152207833](./Sorcerer/image-20250626152207833.png)

7742端口web页面查看源码就可以知道，无论提交什么都会弹窗无效的登录

![image-20250626152329066](./Sorcerer/image-20250626152329066.png)

zipfiles目录下有一些zip文件，下载到本地分析，只有max文件夹中有一个shell脚本和xml文件，其他都是用户目录下的默认文件，这里可以先将这四个用户保存到文件中，后面可能会用到

![image-20250626152341070](./Sorcerer/image-20250626152341070.png)

问了一下ai，max目录下的shell脚本是限制max这个用户只能通过ssh的scp来传输文件，不能进行ssh连接和其他命令执行的操作，该shell脚本通常配合`authorized_keys`来使用

![image-20250626152521319](./Sorcerer/image-20250626152521319.png)

![image-20250626155632806](./Sorcerer/image-20250626155632806.png)

![image-20250626152530644](./Sorcerer/image-20250626152530644.png)

`authorized_keys`文件中调用了该shell文件，对ssh认证时做了限制

可以传输文件那就尝试传输一个不执行shell脚本的`authorized_keys`文件，将`authorized_keys`前面那段删除然后上传,直接上传的话报错是因为那边的shell输出太多，看了wp可以用`-O`参数解决

![image-20250626161740948](./Sorcerer/image-20250626161740948.png)

![image-20250626161736719](./Sorcerer/image-20250626161736719.png)

然后使用ssh就可以成功连接了

![image-20250626162007513](./Sorcerer/image-20250626162007513.png)



并且给出的文件夹下还有一个文件，`tomcat-users.xml.bak`文件最后给出了一个web应用程序的`manager-gui`的账号密码

![image-20250626152713284](./Sorcerer/image-20250626152713284.png)

```
tomcat:VTUD2XxJjf5LPmu6
```

## 8080端口

![image-20250626153056517](./Sorcerer/image-20250626153056517.png)

访问manager页面显示权限不足，

![image-20250626153134377](./Sorcerer/image-20250626153134377.png)

# 提权

上面已经通过7742端口的文件得到了shell，local.txt在`dennis`用户目录下

![image-20250626170212720](./Sorcerer/image-20250626170212720.png)

这个通过suid提权

![image-20250626170227145](./Sorcerer/image-20250626170227145.png)

```
/usr/sbin/start-stop-daemon -n $RANDOM -S -x /bin/sh -- -p
```

![image-20250626170605808](./Sorcerer/image-20250626170605808.png)