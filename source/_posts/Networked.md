---
title: HackTheBox-Networked
date: 2025-4-1 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

## nmap

![image-20250326193206383](./Networked/image-20250326193206383.png)

## 80端口

网站中间件为apache

![image-20250326205630726](./Networked/image-20250326205630726.png)

扫目录，在backup有网站源码备份，upload.php是文件上传,photo.php显示了上传之后的文件

![image-20250326193226693](./Networked/image-20250326193226693.png)

源码中lib.php中是一些检查函数，photo.php和upload.php引用了这些检查函数

![image-20250326210829774](./Networked/image-20250326210829774.png)

但如果上传的文件为image.php.png，分离时只会把image分离出来，成功上传后的文件名还是image.php.png，如果apache存在解析漏洞，就会将文件解析为php

并且上传时会识别`mime_content_type`，必须为image/开头![image-20250326211930947](./Networked/image-20250326211930947.png)

写一句话木马时可以加上GIF文件的16进制文件头即可绕过对`mime_content_type`的检测

![image-20250326212023283](./Networked/image-20250326212023283.png)

然后将文件上传，访问之后即可命令执行

![image-20250326212239962](./Networked/image-20250326212239962.png)

![image-20250326212316414](./Networked/image-20250326212316414.png)

反弹shell到攻击机

![image-20250326213138788](./Networked/image-20250326213138788.png)

## get shell

有bash的会话只有root和另外一个用户，要尝试得到guly的shell

![image-20250405224039960](./Networked/image-20250405224039960.png)

`/home/guly`下user.txt无权读取

![image-20250405224306311](./Networked/image-20250405224306311.png)

有一个计划任务，每三分钟执行一次check_attack.php

![image-20250405224327267](./Networked/image-20250405224327267.png)

```php
##check_attack.php 

<?php
require '/var/www/html/lib.php';
$path = '/var/www/html/uploads/';
$logpath = '/tmp/attack.log';
$to = 'guly';
$msg= '';
$headers = "X-Mailer: check_attack.php\r\n";

$files = array();
$files = preg_grep('/^([^.])/', scandir($path));

foreach ($files as $key => $value) {
        $msg='';
  if ($value == 'index.html') {
        continue;
  }
  #echo "-------------\n";

  #print "check: $value\n";
  #将下划线改为点，上传的时候是将点转换为下划线，getnamecheck是将名字转化为ip
  list ($name,$ext) = getnameCheck($value);
  #检查ip是否合法
  $check = check_ip($name,$value);

  if (!($check[0])) {
    echo "attack!\n";
    # todo: attach file
    file_put_contents($logpath, $msg, FILE_APPEND | LOCK_EX);

    exec("rm -f $logpath");
    exec("nohup /bin/rm -f $path$value > /dev/null 2>&1 &");
    echo "rm -f $path$value\n";
    mail($to, $msg, $msg, $headers, "-F$value");
  }
}

?>
```

`check_attack.php`检查了`/var/www/html/upload`下文件名中ip的合法性，ip如果不合法就执行删除日志和删除该文件，但是`$value`是可控的，可以使用分号分割命令，分号分割之后的命令会依次执行

```
例如上传a;id;b这样的文件名
exec("nohup /bin/rm -f $path$value > /dev/null 2>&1 &");
到这一句的时候就会执行
exec("nohup /bin/rm -f $path a;id;b > /dev/null 2>&1 &");
分号分割之后会依次执行，等同于
exec("nohup /bin/rm -f $path a)
exec("id")
exec(";b > /dev/null 2>&1 &")

所以将id换为反弹shell的命令。就可以反弹guly的shell
```

![image-20250405234341949](./Networked/image-20250405234341949.png)

等待一会就可以得到`guly`的shell

![image-20250405234428713](./Networked/image-20250405234428713.png)

## 提权

![image-20250405234554615](./Networked/image-20250405234554615.png)

运行这个脚本会生成一个网络配置

根据这篇文章[通过网络脚本获取 Redhat/CentOS root - 漏洞利用 --- Redhat/CentOS root through network-scripts - Exploit](./https://vulmon.com/exploitdetails?qidtp=maillist_fulldisclosure&qid=e026a0c5f83df4fd532442e1324ffa4f)

当我输入空格加命令之后会进行命令执行，每个不同的参数都输入不同的命令，看看哪个参数会进行命令执行

![image-20250405235534661](./Networked/image-20250405235534661.png)

id会执行，我们将name命名为bash会话，即可得到root的shell

![image-20250405235659438](./Networked/image-20250405235659438.png)