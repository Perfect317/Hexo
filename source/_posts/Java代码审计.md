---
title: JAVA代码审计
date: 2025-10-14 20:00:00
tags: JAVA
categories: Java安全-代码审计
---



# sql注入

## 连接数据库的方式

> 在java中，有两种方式连接数据库：JDBC和mybatis框架
>
> - JDBC：JDBC 是 Java 提供的一种标准数据库连接API。它允许开发者通过编写 SQL 语句和 Java 代码来连接和操作数据库。
>
> - MyBatis：MyBatis 是一个开源的持久层框架，它简化了在 Java 应用程序中使用 JDBC 的过程。它提供了一种将 SQL 和 Java 代码分离的方式，通过 XML 或注解来配置 SQL 语句和映射关系，减少了代码冗余和复杂性。
>
>
>
> MyBatis只是简化java使用JDBC过程，可以更加方便使用，底层还是使用JDBC连接数据库，而JDBC连接数据库有两种方法：
>
> - 直接拼接：直接拼接是通过使用 Statement对象来执行 SQL 语句，是在 Java 代码中直接将变量值嵌入到 SQL 语句中，然后将整个 SQL 语句作为字符串传递给数据库执行。这种方法如果变量值没有经过适当的处理，就容易产生SQL注入漏洞
>
> - 预编译：预编译是通过使用 PreparedStatement 对象来执行 SQL 语句。在预编译阶段，SQL 语句会被发送到数据库进行编译，同时还可以将变量作为占位符传递进去。这种方法是不容易产生SQL注入
>   

## 代码审计

### 关键字搜索

```
// 1、关键字搜索
select、insert、update、delete

// 2、JDBC审计
// 预编译搜索
.prepareStatement
PreparedStatement 
CallableStatement
// 可预编译可非预编译，看内部使用的具体是什么
execute(
executeQuery(

// 3、MyBatis审计
搜索Mapper.xml文件中的${
// 无漏洞写法
SELECT * FROM tbuser where id = #{id}
SELECT * FROM tbuser where username like concat('%',#{username},'%')
// 有漏洞写法
SELECT * FROM tbuser where username = '${username}'
SELECT * FROM tbuser where id in (${ids})
SELECT * FROM tbuser where username like '%${username}%'
SELECT * FROM tbuser where id in (${ids})
SELECT * FROM tbuser where order by ${colName}  //这里如果用#是没有排序效果的
//在mybatis中，order by 、in 、like 几种场景不能使用预编译
// 因此对于Mybatis 的SQL注入，我们可以在IDEA中直接搜索如下关键字：
$、like、in、order by
```



### JDBC直接拼接

```java
String sql = "select * from users where id = "+req.getParameter("id");
Statement st = con.createStatement();
ResultSet rs = st.executQuery(sql);
```

### MyBatis拼接造成SQL注入：

```java
<select id="queryAll"  resultMap="resultMap">
  SELECT * FROM NEWS WHERE ID = #{id} // #{}使用预编译，安全
  SELECT * FROM NEWS WHERE ID = ${id}  // ${}使用拼接SQL，不安全
</select>
```

**1.使用in语句之的多个参数**
in之后多个id查询时，容易导致SQL注入，在一些删除语句中容易出现，由于无法确定参数个数，而使用直接拼接方式，就容易造成SQL注入:

```
delete from news where id in("+ids+")
```

在in这种情况中，哪怕使用预编译，比如在mybits框架，也容易出现SQL注入

```
Select * from news where id in (#{ids})
```


对于 IN 语句，如果直接使用 # 进行参数绑定，那么在拼接 SQL 语句时会将整个参数值作为一个整体拼接进去，而不会将参数值当作多个独立的值对待

**2、使用like语句进行模糊查询**

LIKE 运算符用于在 WHERE 子句中进行模糊匹配，很容易出现拼接情况，就容易造成SQL注入

```
String sql = "select * from users where password like '%" + con + "%'"
```

在mybaits框架中：

```
Select * from news where title like ‘%#{title}%’
这种写法是错误，会报错，而正确的写法是：
Select * from news where title like '%${title}%'
这就容易造成SQl注入
```


**3、Order by、from等无法预编译，**

使用order by语句时是无法使用预编译的，因为数据库需要在执行查询之前知道如何进行排序。这意味着无法使用预编译语句中的 ? 占位符来代表列名，所以就需要采用拼接方式

```
Select * from news where title =?" + "order by '" + time + "' asc
```

# XXE（XML外部实体注入）

![image-20251014144944078](https://image.liam317.top/2025/10/4b5108f7d3c5cbbd919a447a380be8af.png)

在DTD部分可以分为`内部声明实体`和`引用外部实体`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE example [
内部声明实体internalEntity
<!ENTITY internalEntity "This is an internal entity">
//引用外部实体xternalEntity
<!ENTITY externalEntity SYSTEM "http://www.example.com/externalEntity.xml">
]>
<example>
  <content>
    &internalEntity; and &externalEntity; 
  </content>
</example>
```

所以XXE（XML外部实体引用）原理就是，没有禁用DTD部分中外部实体引用，导致攻击者可以加载外部的XML文件,造成敏感信息泄露等后果

## 代码审计

要对java代码审计xxe漏洞，更加具体的话，就是从两个方面出发

- 对于没有使用xml外部实体的网站，查看是否禁用xml外部实体
- 对于引用xml外部实体的网站，查看使用使用xml文件的相关配置,是否安全

1、查看是否禁用XML外部实体

在Java中，XML外部实体（XXE）是默认开启的，所以如果没有特意进行配置，就是已经允许加载XMl外部实体，可以去检查解释器的配置，是否禁用

```java
DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
try {
    //禁止解析XML文档声明的doctype部分：
    factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
    //禁止解析XML文档中的外部通用实体：
    factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
    //禁止解析XML文档中的外部参数实体：
    factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
    //设置启用安全处理特性
    factory.setFeature("http://javax.xml.XMLConstants/feature/secure-processing", true);
    //禁止XInclude的支持
    factory.setXIncludeAware(false);
    //禁止XML文档解析器扩展实体引用
    factory.setExpandEntityReferences(false);
    DocumentBuilder builder = factory.newDocumentBuilder();
    builder.parse(new InputSource(new StringReader("<!DOCTYPE foo [<!ENTITY xxe SYSTEM 'file:///etc/passwd' >]><foo>&xxe;</foo>")));
    System.out.println("External Entities are enabled!");
} catch (Exception e) {
    System.out.println("External Entities are disabled!");
}
```

# 反序列化漏洞

**1、原生的Java反序列化：**

在 Java 中，要实现对象的序列化和反序列化，对象必须实现 `Serializable` 接口或 `Externalizable` 接口：

Serializable 接口：实现了 Serializable 接口的类可以通过 Java 的默认机制进行序列化和反序列化，该接口是一个标记接口，不包含任何方法，只是作为序列化和反序列化的标志。

Externalizable 接口：与 Serializable 接口不同，实现 Externalizable 接口的类需要显式地实现 writeExternal() 和 readExternal() 两个方法

进行反序列化过程需要用到输入输出流来实现序列化和反序列化

`java.io.ObjectOutputStream` 类的 `writeObject()` 方法可以实现序列
`java.io.ObjectInputStream` 类的` readObject()` 方法用于实现反序列化

**2、与框架相关的java反序列化：**

- `Apache Struts` 反序列化漏洞（CVE-2017-5638）：该漏洞影响 `Apache Struts` 框架，攻击者可以通过构造特殊的 Content-Type 标头来注入恶意的 OGNL 表达式，从而执行远程命令。
- `Apache Commons Collections` 反序列化漏洞（CVE-2015-6420）：`Apache Commons Collections` 库中存在漏洞，攻击者可以构造恶意的序列化数据来触发远程代码执行。
- `Jackson` 反序列化漏洞：`Jackson` 是用于处理 JSON 数据的流行 Java 库。曾经发现过多个 `Jackson` 反序列化漏洞，例如 `Jackson-databind` 反序列化漏洞（CVE-2017-7525、CVE-2018-19362），攻击者可以通过构造恶意 JSON 数据来执行任意代码。
- `JBoss Seam` 反序列化漏洞（CVE-2010-1871）：JBoss Seam 是一个用于开发 Java EE 应用程序的框架，曾出现反序列化漏洞，攻击者可以通过精心构造的序列化数据实现远程代码执行。
- `WebLogic` 反序列化漏洞（CVE-2017-10271）：该漏洞影响 `Oracle WebLogic Server`，攻击者可以通过发送恶意的 T3 协议请求，利用 `WebLogic` 进行远程代码执行

# CSRF漏洞

**查看是否检测referer、token等参数**

> 检查referer、token是防御CSRF漏洞的常用方法，如果网站没有检测，或是检测不严，就可能存在CSRF漏洞
>
> - 检测Referer：Referer是HTTP请求头字段，它指示了当前请求页面的来源页面的URL。在CSRF攻击中，攻击者通常无法伪造请求的Referer字段，因为Referer字段由浏览器自动生成并发送。因此，服务器可以检查Referer字段来验证请求的来源是否合法。如果Referer字段为空或与当前页面的来源不匹配，服务器可以拒绝请求。
>
> - 使用Token：Token是一种随机生成的令牌，它可以防止CSRF攻击。服务器在生成页面时，将Token嵌入到页面中（通常是作为隐藏表单字段的一部分）。当用户提交表单时，服务器会检查表单中的CSRF Token与服务器生成的Token是否匹配。如果不匹配，服务器会拒绝请求

# 文件上传漏洞

## 代码审计

### 1、查看前端的文件过滤，

查看文件类型、文件大小、文件名称（之所以除了查看类型之外，还查看大小，文件名，是防其他漏洞）：

- 文件类型验证：防文件上传，防攻击者上传webshell文件

- 文件大小验证：防DOS攻击，大量上传超大内存文件，会造成dos

- 文件名称验证：防XSS攻击，文件名插入XSS的payload会造成xss攻击


### 2、查看后端的文件过滤

后端处理和前端一样，要查看类型、大小、文件名，还要验证文件内容、存储路径，是否返回信息

- 文件类型验证：检查是否在后端对文件类型进行了验证。
- 文件内容验证：检查是否对文件内容进行了验证。查看内容是否由恶意代码
- 文件名验证：检查是否对上传的文件名进行了验证。特别是文件扩展名部分，
- 存储路径：检查是否对文件的存储路径进行了合理设置，防止目录遍历漏洞出现。
- 文件重命名：为防止文件覆盖，采用唯一命名方式（如UUID）是一种常见的做法。
- 返回信息：注意返回给前端的信息，比如，返回上传文件的绝对路径，可能导致路径泄露。



# SSRF漏洞

**1、快速找到SSRF 可能存在区域，就是找到HTTP请求操作函数**
以下是常用于处理HTTP请求库：

```
HttpURLConnection.getInputStream
HttpURLConnection.connect
URLConnection.getInputStream
HttpClient.execute
HttpClient.executeMethod
Request.Get.execute
Request.Post.execute
URL.openStream
ImageIO.read
OkHttpClient.newCall.execute
HttpServletRequest
BasicHttpRequest
```

# 命令执行漏洞

**1）快速找到常用执行命令函数：**

- System.exec()：Java中用于启动外部进程的方法。
- getRuntime().exec()：获取Java运行时对象并使用其执行外部命令的方法。
- Runtime.exec()：Java中用于执行外部命令的方法。
- ProcessBuilder：Java中创建和管理进程的类。
- ShellExecute：与Windows平台上执行外部命令相关的函数。
- wsystem()：与Windows平台上执行外部命令相关的函数。
- /bin/sh、/bin/bash、cmd：常见的命令行Shell解释器路径

**2）测试命令执行漏洞**

首先通过代码审计，找到前端代码中调用后端接口的位置，是哪些接口请求最终调用了这些命令执行函数
其次对请求接口的参数进行测试：测试是否可以通过修改请求参数来触发命令执行漏洞