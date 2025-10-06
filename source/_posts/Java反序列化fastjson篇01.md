---
title: Java反序列化fastjson篇01-漏洞原理
date: 2025-10-4 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

## 环境搭建

- 演示中用的是jdk8u65，其他版本应该也行

- pom.xml中添加

  ```xml
      <dependencies>
          <dependency>
           <groupId>com.alibaba</groupId>
           <artifactId>fastjson</artifactId>
           <version>1.2.24</version>
          </dependency>
      </dependencies>
  ```



# 代码demo

## student类

```java
public class Student {  
    private String name;  
 private int age;  
  
 public Student() {  
        System.out.println("构造函数");  
 }  
  
    public String getName() {  
        System.out.println("getName");  
 return name;  
 }  
  
    public void setName(String name) {  
        System.out.println("setName");  
 this.name = name;  
 }  
  
    public int getAge() {  
        System.out.println("getAge");  
 return age;  
 }  
  
    public void setAge(int age) {  
        System.out.println("setAge");  
 this.age = age;  
 }  
}
```

## 序列化代码

```java
package org.example;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.serializer.SerializerFeature;

public class Main {

// 最开始的序列化 demopublic class StudentSerialize {
public static void main(String[] args) {
        Student student = new Student();
         student.setName("Drunkbaby");
//        student.setAge(6);
        String jsonString = JSON.toJSONString(student, SerializerFeature.WriteClassName);
        System.out.println(jsonString);
    }
}
```

调试一下，在`toJSONString`处断点，进入`toJSONString`时执行的第一条代码就加上了@type这个字段

![image-20251004175837236](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96fastjson%E7%AF%8701/image-20251004175837236.png)

运行后的内容中也就出现`@type`字段，`@type`字段指定了反序列化的类名

![image-20251004180237489](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96fastjson%E7%AF%8701/image-20251004180237489.png)

## 反序列化代码

```java
package org.example;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.parser.Feature;
import org.example.Student;

public class unserialize {
    public static void main(String[] args) {  
        String jsonString = "{\"@type\":\"org.example.Student\",\"age\":0,\"name\":\"Drunkbaby\"}";
        Student student = JSON.parseObject(jsonString, Student.class, Feature.SupportNonPublicField);
        System.out.println(student);

 }  
}
```

运行结果如下，反序列化时会调用其中的`getter`方法的`setter`方法，但是并不会调用所有的`getter`方法和`setter`方法

![image-20251004181416836](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96fastjson%E7%AF%8701/image-20251004181416836.png)

满足条件的setter：

- 非静态函数
- 返回类型为void或当前类
- 参数个数为1个

满足条件的getter：

- 非静态方法
- 无参数
- **返回值类型继承自Collection或Map或AtomicBoolean或AtomicInteger或AtomicLong**

# 漏洞原理

`@type`指定了要反序列化为哪个对象，并且会调用其中的setter方法，那么利用这个特性，就可以自己构造json字符串，让@type后面的库变为攻击类库