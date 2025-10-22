---
title: JAVA安全-内存马-环境搭建
date: 2025-10-8 20:00:00
tags: JAVA
categories: Java安全-内存马
---

# Servlet+comcat环境搭建

## 前言

网上写的比较少，并且好多都是很早以前的IDEA版本了，当前用的版本是`IDEA 2024.1.2`

![image-20251008173254967](C:/Users/Liao1/AppData/Roaming/Typora/typora-user-images/image-20251008173254967.png)



## 环境搭建

- jdk 1.8.0_202
- tomcat 8.5.81
- maven 3.9.6
- IDEA 2024.1.2

`Drunkbaby`师傅用的是 `IDEA 2021.2.1`，在创建项目时有`Java Enterprise`，后面的版本没有了，我们就从基本的开始



### 先创建maven项目

![image-20251008173611624](https://image.liam317.top/2025/10/5ab44676308ed8efa34edbe06004455d.png)

### 添加框架

鼠标放在项目名称上双击`shift`，添加框架支持

![image-20251008173654807](https://image.liam317.top/2025/10/aecce6e3c3c9c4123f56007b340d23d3.png)

选择web应用程序，并且创建web.xml

![image-20251008173724908](https://image.liam317.top/2025/10/7c7c5fdd30c3c934591d55fbac37cd23.png)

### pom.xml

在`pom.xml`中添加依赖

```xml
    <dependencies>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>servlet-api</artifactId>
            <version>2.5</version>
        </dependency>
        <dependency>
            <groupId>javax.servlet.jsp</groupId>
            <artifactId>jsp-api</artifactId>
            <version>2.2</version>
        </dependency>
        <dependency>
            <groupId>junit</groupId>
            <artifactId>junit</artifactId>
            <version>4.12</version>
        </dependency>
        <dependency>
            <groupId>org.springframework</groupId>
            <artifactId>spring-webmvc</artifactId>
            <version>5.1.9.RELEASE</version>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>servlet-api</artifactId>
            <version>2.5</version>
        </dependency>
        <dependency>
            <groupId>javax.servlet.jsp</groupId>
            <artifactId>jsp-api</artifactId>
            <version>2.2</version>
        </dependency>
        <dependency>
            <groupId>javax.servlet</groupId>
            <artifactId>jstl</artifactId>
            <version>1.2</version>
        </dependency>
    </dependencies>

```

### 导入jar包

导入`servlet_api.jar`包，右上角设置->项目结构->模块->依赖->添加jar包

![image-20251008174117277](https://image.liam317.top/2025/10/78f1bf01c40e8b6e137eb3ef732d7f5c.png)

`servlet-api.jar`包的位置在`tomcat`安装目录下的`lib`文件夹中

![image-20251008174155027](https://image.liam317.top/2025/10/1f820a6fce8eb4004363c8bf14ad59d8.png)

### 编辑tomcat

然后配置tomcat,`设置->构建、执行、部署->应用程序服务器->添加tomcat服务器->选择下载的tomcat就可以了`

![image-20251008174430397](https://image.liam317.top/2025/10/316482e6d500388ee72ec03c895197c9.png)

![image-20251008174443322](https://image.liam317.top/2025/10/4a294992dbe49e481ad7a268c8974ef6.png)

运行/调试编辑，

![image-20251008174649791](https://image.liam317.top/2025/10/2808e1a2bf49ba8ff1ecea8c277709c4.png)

![image-20251008174716939](https://image.liam317.top/2025/10/8ed01bf897c140169a39a85794198875.png)

然后去工件添加一个，Web应用程序：展开型

![image-20251008174850555](https://image.liam317.top/2025/10/e01971ae0c424cb7f55d98e19d48c9e3.png)

## 测试

在`src/main/java`下创建一个`filter.java`文件

```java
import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import java.io.IOException;

@WebFilter("/*")
public class filter implements Filter{
    @Override
 public void init(FilterConfig filterConfig) throws ServletException {
        System.out.println("Filter 初始构造完成");
 }

    @Override
 public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
        System.out.println("执行了过滤操作");
 filterChain.doFilter(servletRequest,servletResponse);
 }

    @Override
 public void destroy() {

    }
}
```

在web/Web-INF/web.xml中添加

```xml
        <filter>
        <filter-name>filter</filter-name>
        <filter-class>filter</filter-class>
    </filter>
    <filter-mapping>
        <filter-name>filter</filter-name>
        <url-pattern>/filter</url-pattern>
    </filter-mapping>
```

然后运行项目，就可以发现已经加载自定义的filter了

![image-20251008175800164](https://image.liam317.top/2025/10/c0ccf913db1870b55216d078978c3f33.png)