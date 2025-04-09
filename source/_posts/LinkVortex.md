---
title: HackTheBox-LinkVortex
date: 2025-4-7 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



# nmap



![image-20250407151103836](./LinkVortex/image-20250407151103836.png)

# 80端口

## dirsearch

![image-20250407151127555](./LinkVortex/image-20250407151127555.png)

![image-20250407151554512](./LinkVortex/image-20250407151554512.png)

http://linkvortex.htb/ghost下是个登录页面

![image-20250407162224281](./LinkVortex/image-20250407162224281.png)

## 子域名爆破(dev.linkvortex.htb)

### git泄露

![image-20250407153200314](./LinkVortex/image-20250407153200314.png)

![image-20250407154029712](./LinkVortex/image-20250407154029712.png)

![image-20250407154040131](./LinkVortex/image-20250407154040131.png)

### /.git/config

git.config中有Ghost博客的版本号,该版本存在任意文件读取[CVE-2023-40028](./https://cve.imfht.com/detail/CVE-2023-40028)，需要登录

![image-20250407155101983](./LinkVortex/image-20250407155101983.png)

### git泄露提取

[Git_Extract: 提取远程 git 泄露或本地 git 的工具](./https://github.com/gakki429/Git_Extract)

[WangYihang/GitHacker](./https://github.com/WangYihang/GitHacker)

相比之下`GitHacker`好像快一点

![image-20250407154049214](./LinkVortex/image-20250407154049214.png)

#### Dockerfile

git泄露了一个dockerfile:ghost和一个文件夹

![image-20250407171148680](./LinkVortex/image-20250407171148680.png)

dockerfile中有配置文件的默认路径，后面任意文件读取可以尝试读取

![image-20250407174311323](./LinkVortex/image-20250407174311323.png)

#### Authentication.test.js

```
最终在git泄露的目录下发现一个authentication.test.js
GitHack-master/dev.linkvortex.htb/ghost/core/test/regression/api/admin/authentication.test.js
```

该文件下有很多账号密码

![image-20250407161839585](./LinkVortex/image-20250407161839585.png)

```
test@example.com:OctopiFociPilfer45
```

![image-20250407161909294](./LinkVortex/image-20250407161909294.png)

```
test-leo@example.com:thisissupersafe
```

![image-20250407162033655](./LinkVortex/image-20250407162053742.png)

```
test@example.com:thisissupersafe
```

![image-20250407161949457](./LinkVortex/image-20250407161949457.png)

```
not-invited@example.org:lel123456
```

使用上面的账号密码都登录失败，将`example.org`替换为`linkvortex.htb`也登录失败，该文件的目录是在/api/admin下，将用户名换位`admin`尝试登录，登录成功

```
admin@example.com:OctopiFociPilfer45
```

### 任意文件读取

[CVE-2023-40028：EXP](./https://github.com/0xDTC/Ghost-5.58-Arbitrary-File-Read-CVE-2023-40028)利用现成exp进行任意文件读取

![image-20250407170347697](./LinkVortex/image-20250407170347697.png)

读取dockerfile中的默认配置文件

```
/var/lib/ghost/config.production.json
```

![image-20250407174417397](./LinkVortex/image-20250407174417397.png)

```
bob@linkvortex.htb:fibber-talented-worth
```

得到bob的账号，尝试ssh登录,可以成功登录

# 提权

sudo -l 查看用户有哪些以sudo权限运行的命令

![image-20250407175345666](./LinkVortex/image-20250407175345666.png)

这个脚本的作用是检查传入的是否是 `.png` 格式的符号链接；

如果是：

- 并且链接指向敏感目录(etc或root)，则删除；
- 否则移动到隔离目录 `/var/quarantined`；
- 如果环境变量 `CHECK_CONTENT` 为 true，则显示被隔离链接的内容。



先设置环境变量`CHECK_CONTENT`为true

创建`Link1.png`放在`/home/bob`下链接到`/root/root.txt`，指向的是敏感目录，这样直接运行这个脚本会删除这张图片，再创建一个`link2.png`链接`Link1.png`，这样运行时该脚本检查`Link2.png`时就会放入`/var/quarantined`目录，并且环境变量中`CHECK_CONTENT`为true，会打印文件内容，打印的是`link1.png`，link1.png又链接到root.txt就会打印root.txt

![image-20250407182704911](./LinkVortex/image-20250407182704911.png)

![image-20250407182725348](./LinkVortex/image-20250407182725348.png)
