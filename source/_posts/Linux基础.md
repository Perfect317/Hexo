---
title: linux基础
date: 2025-03-18 14:12:32
tags: linux精讲
categories: Linux
---



## netstat

- `-t` tcp协议
- `-u` udp协议
- `-l` listen模式
- `-s` 列出网络使用统计信息
- `-t` 列出带有服务器名称和`PID`连接信息
- `-i` 显示具体网口信息
- `-a` 显示所有套接字
- `-n` 不解析名称
- `-o` 显示计时器

## find

`-name` 最常用的find命令， / 表示的是目录

```
find / -name flag.txt
```

***



`-type` 查找对应格式

- `-d(directory)` 为目录

- `-f(file)` 为文件

> 查找名为config的目录
>
> ```
> find / -type d -name config
> ```
>
> 查找名为passwd的文件
>
> ```
> find / -type f -name passwd
> ```

***



`-perm` 查找对应权限

> **4=r 2=w 1=x -=0**

```
find / -type f -perm 777
//查找可执行文件
find / -perm a=x
//a：表示所有用户（所有者、组用户、其他用户）
//u：表示文件的所有者（user）。
//g：表示文件的所属组（group）。
//o：表示其他用户（others）。

```

***



`-user` 查找用户的所有文件

```
find / -user frank
```

***



`-mtime`查找最近10天内修改的文件

`-atime`查找最近10天内访问的文件

`cmin`查找过去一小时内更改的文件

`amin`查找过去一小时内访问的文件

`size`查找对应大小的文件，此命令还可以与 （+） 和 （-） 符号一起使用，以指定大于或小于给定大小的文件。

```shell
fing / -size +100M
```

查找全局可写文件

> ```shell
> find / -writable -type d 2>/dev/null
> ```
>
> ```shell
> find / -perm -222 -type d 2>/dev/null
> ```
>
> ```shell
> find / -perm -o w -type d 2>/dev/null
> ```

查找开发工具和支持的语言：

> ```
> find / -name perl*
> ```
>
> ```
> find / -name python*
> ```
>
> ```
> find / -name gcc*
> ```

查找特定文件权限：

```
find / -perm -u=s -type f 2>/dev/null
```



## 重定向

|          |        | 文件描述符 |
| -------- | ------ | ---------- |
| 标准输入 | stdin  | 0          |
| 标准输出 | stdout | 1          |
| 标准错误 | stderr | 2          |

****

**管道输出符只会识别标准输出的内容**

****

如果想将输出重定向到某一文件描述符，则需要借助`>&`运算符并跟上文件描述符来完成

```shell
echo "no changes" >&1 | sed "s/no/some/"
some changes
//将no changes当做stdout输出
echo "no changes" >&2 | sed "s/no/some/"
no changes
//将no changes当做stderr输出
```

### 常见用法

将标准错误输出到/dev/null，只显示标准输出

```shell
find / -size +100M -type f 2>/dev/null
```

将错误重定向为标准输出

```shell
cat ttt 2>&1
```

## ps

##### 查看进程树

```
ps axjf
ps aux
```

`aux` 选项将显示所有用户的进程 （a），显示启动进程的用户 （u），并显示未连接到终端的进程 （x）。查看 ps aux 命令输出，我们可以更好地了解系统和潜在漏洞。

## sort

语法

```shell
sort [-bcdfimMnr][-o<输出文件>][-t<分隔字符>][+<起始栏位>-<结束栏位>][--help][--verison][文件][-k field1[,field2]]

```

参数说明：

> - -b 忽略每行前面开始出的空格字符。
> - -c 检查文件是否已经按照顺序排序。
> - -d 排序时，处理英文字母、数字及空格字符外，忽略其他的字符。
> - -f 排序时，将小写字母视为大写字母。
> - -i 排序时，除了040至176之间的ASCII字符外，忽略其他的字符。
> - -m 将几个排序好的文件进行合并。
> - -M 将前面3个字母依照月份的缩写进行排序。
> - -n 依照数值的大小排序。
> - -u 意味着是唯一的(unique)，输出的结果是去完重了的。
> - -o<输出文件> 将排序后的结果存入指定的文件。
> - -r 以相反的顺序来排序。
> - -t<分隔字符> 指定排序时所用的栏位分隔字符。
> - +<起始栏位>-<结束栏位> 以指定的栏位来排序，范围由起始栏位到结束栏位的前一栏位。
> - --help 显示帮助。
> - --version 显示版本信息。
> - [-k field1[,field2]] 按指定的列进行排序。





## ln

 硬链接可认为是一个文件拥有两个文件名;而软链接则是系统新建一个链接文件，此文件指向其所要指的文件。此外，软链接可对文件和文件夹，而硬链接仅针对文件。

```
ln -s abc cde    #建立abc 的软连接 
ln abc cde       #建立abc的硬连接
```

## 用户，用户组权限

### usermod

只有 root 或具有[sudo](./https://linuxize.com/post/sudo-command-in-linux/) 访问权限的用户才能调用`usermod`和修改用户帐户。成功后，该命令不会显示任何输出。

最典型的用例`usermod`是将用户添加到组中。

要将现有用户添加到辅助组，请使用`-a -G`组名和用户名后面的选项：

```
usermod -a -G GROUP USER
```

### chown

修改文件和目录的所有者和所属组

当只需要修改所有者时，可使用如下 chown 命令的基本格式：

```
[root@localhost ~]# chown [-R] 所有者 文件或目录
```

-R（注意大写）选项表示连同子目录中的所有文件，都更改所有者。

如果需要同时更改所有者和所属组，chown 命令的基本格式为：

```
[root@localhost ~]# chown [-R] 所有者:所属组 文件或目录
```

# 文本处理

## cut 命令

**使用说明:**

cut 命令从文件的每一行剪切字节、字符和字段并将这些字节、字符和字段写至标准输出。

如果不指定 File 参数，cut 命令将读取标准输入。必须指定 -b、-c 或 -f 标志之一。

**参数:**

- `-b` ：以字节为单位进行分割。这些字节位置将忽略多字节字符边界，除非也指定了 -n 标志。
- `-c`：以字符为单位进行分割。
- `-d`：自定义分隔符，默认为制表符。
- `-f` ：与-d一起使用，指定显示哪个区域。
- `-n` ：取消分割多字节字符。仅和 -b 标志一起使用。如果字符的最后一个字节落在由 -b 标志的 List 参数指示的 范围之内，该字符将被写出；否则，该字符将被排除

例：只输出/etc/passwd 中的用户名

```
cat /etc/passwd | cut -d ":" -f 1
```

## sed

- `-n` 默认情况下，sed会打印所有行到标准输出，如果使用了`-n`选项只有被sed处理的行才会被打印
- `p`打印匹配的行
- `d`删除匹配的行
- `a\text`：在匹配的行后追加text
- `i\text`：在匹配的行前插入text
- `c\text`：用文本text替换匹配的行
- `s\pattern\replacement\flags`：替换文本，pattern是要被替换的字符，replacement是被替换后的字符，flags是修饰符，（g代表全局 ）

## awk

`$0`	: 代表当前行(相当于匹配所有)

`$n`	: 代表第n列

```
案例1:(以:为分隔符)
awk -F: '{print $1}' /etc/passwd 
```

```
案例2:(默认空格为分隔符)
awk '{print $1}' /etc/passwd
```

```
统计每行的总字段
awk '{print NF}' 2.txt
```

## tr

**参数说明：**

- -c, --complement：反选设定字符。也就是符合 SET1 的部份不做处理，不符合的剩余部份才进行转换
- -d, --delete：删除指令字符
- -s, --squeeze-repeats：缩减连续重复的字符成指定的单个字符
- -t, --truncate-set1：削减 SET1 指定范围，使之与 SET2 设定长度相等
- --help：显示程序用法信息
- --version：显示程序本身的版本信息

```
所有小写字母转换为大写字母
cat testfile |tr a-z A-Z 
```

## tee

Linux tee命令用于读取标准输入的数据，并将其内容输出成文件。



## Linux tee命令

Linux tee命令用于读取标准输入的数据，并将其内容输出成文件。

tee指令会从标准输入设备读取数据，将其内容输出到标准输出设备，同时保存成文件。

## wc（word count）

统计行数

wc -l file.txt

