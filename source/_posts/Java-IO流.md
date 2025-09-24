---
title: Java-IO流
date: 2025-7-01 20:00:00
tags: JAVA
categories: JAVA安全-基础篇
---



## 创建文件

创建文件有三种方法

```java
//直接写路径
File file1 = new file("C:\\Users\\Administrator\\IdeaProjects\\test\\out\\test1.txt");

//通过两个String类型指定路径和文件名
String Partent = "C:\\Users\\Administrator\\IdeaProjects\\test\\out";
String Child = "test2.txt"
File file2 = new file (Partent,Child);

//通过String指定路径，直接指定文件名
File file3 = new file ("C:\\Users\\Administrator\\IdeaProjects\\test\\out");
File file4 = new file (file3,"test3.txt");
```

## File类的其他函数

```java
//具体使用时会自动补全
file.getAbsolutePath();  //绝对路径
file.getName(); //文件名
file.delete();	//文件删除
```

目录操作也是同理，只不过File实例化类时指定的是目录

同样可以进行增删查改操作

## 文件读取和写入

### 文件读取

```java
import javax.swing.plaf.synth.SynthOptionPaneUI;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.sql.SQLOutput;

public class fileread {
    public static void main(String[] args) {
        String filePath = "C:\\Users\\Administrator\\IdeaProjects\\test\\test.txt";
        FileInputStream fileInputStream = null;
        int readData = 0;
        try{
            fileInputStream = new FileInputStream(filePath);
            while((readData = fileInputStream.read())!=-1){
                System.out.print((char)readData);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        finally {
            try{
                fileInputStream.close();
            }
            catch (IOException e){
                e.printStackTrace();
            }
        }
    }
}

```

### 文件写入

```java
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

public class FileWrite {
    public static void main(String[] args) {
        writefile();
    }
    public static void writefile(){
        String filepath = "C:\\Users\\Administrator\\IdeaProjects\\test\\test.txt";
        FileOutputStream fileOutputStream = null;
        try{
            fileOutputStream = new FileOutputStream(filepath, true); // true for append mode
            String content = "Hello, this is a test write operation.\n";
            try{
                fileOutputStream.write(content.getBytes(StandardCharsets.UTF_8),3,10);

            }catch (IOException e){
                e.printStackTrace();
            }finally {
                fileOutputStream.close();
            }

        }catch (IOException e)
        {
            e.printStackTrace();
        }
    }
}

```

