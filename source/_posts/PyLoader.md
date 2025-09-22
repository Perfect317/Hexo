```
title: Proving Grounds Practice-Pyloader
date: 2025-9-16 20:00:00
tags: 红队
categories: 红队打靶-Linux
```



# 信息收集

## nmap

![image-20250916143859585](./PyLoader/image-20250916143859585.png)

# 9666端口

这个端口默认界面是个登录界面，使用默认密码`pyload:pyload`即可登录

![image-20250916145828957](./PyLoader/image-20250916145828957.png)

登录之后查看左上角的info，其中有版本号0.5.0

![image-20250916150830992](./PyLoader/image-20250916150830992.png)

经过查询该版本存在[Remote Code Execution (RCE) - Python webapps Exploit](./https://www.exploit-db.com/exploits/51532)

直接运行exp执行命令即可

![image-20250916150917266](./PyLoader/image-20250916150917266.png)

![image-20250916150932771](./PyLoader/image-20250916150932771.png)

拿到的直接就是root权限

![image-20250916150922851](./PyLoader/image-20250916150922851.png)