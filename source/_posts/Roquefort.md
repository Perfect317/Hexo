---
title: Proving Grounds Practice-Roquefort
date: 2025-7-17 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250717132645110](./Roquefort/image-20250717132645110.png)

# 3000端口

3000端口部署的`gitea 1.75版本`，

![image-20250717143146332](./Roquefort/image-20250717143146332.png)

[Gitea 1.7.5 - Remote Code Execution - Multiple webapps Exploit](./https://www.exploit-db.com/exploits/49383?source=post_page-----4328214f4da3---------------------------------------)

搜索一下该版本存在远程代码执行，摸索了半天这个exp也没能使用

查看了其他的利用手法是修改了hook函数的内容，每次更新时都会运行update这个勾子，修改这个勾子的内容即可

![image-20250717143938847](./Roquefort/image-20250717143938847.png)

尝试了多个反弹shell的代码都会报错，先打印一下`/etc/passwd`，是可以成功命令执行。

![image-20250717144039957](./Roquefort/image-20250717144039957.png)

将我的公钥写入靶机，使用我的私钥来连接

![image-20250717154707781](./Roquefort/image-20250717154707781.png)

![image-20250717154719831](./Roquefort/image-20250717154719831.png)

![image-20250717155332060](./Roquefort/image-20250717155332060.png)

然后就可以成功连接了

# 提权

wget无法下载linpeas.sh，使用scp上传到靶机

![image-20250717155432191](./Roquefort/image-20250717155432191.png)

查找可写的路径，其中/usr/local/bin可写

![image-20250717164059322](./Roquefort/image-20250717164059322.png)

并且发现了run-parts是以root用户在运行定时任务

![image-20250717164152627](./Roquefort/image-20250717164152627.png)

该脚本在/bin目录下

![image-20250717164233381](./Roquefort/image-20250717164233381.png)

查看环境变量，我们可写的目录`/usr/local/bin`优先级在`/bin`目录之上，所以可以在`/usr/local/bin`下写一个恶意的`run-parts`，运行时就会执行`/usr/local/bin`下写的`run-parts`

等待一会就会执行这个恶意脚本

![image-20250717164325952](./Roquefort/image-20250717164325952.png)

![image-20250717165634254](./Roquefort/image-20250717165634254.png)

![image-20250717165640481](./Roquefort/image-20250717165640481.png)

![image-20250717165646509](./Roquefort/image-20250717165646509.png)