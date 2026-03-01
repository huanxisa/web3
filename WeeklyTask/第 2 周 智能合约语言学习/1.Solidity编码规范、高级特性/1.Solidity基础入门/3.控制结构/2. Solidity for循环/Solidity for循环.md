
想象一下，如果我们要计算 `1+2+3` 的和，这很简单：

```
uint256 sum = 1+2+3;
```

但是如果我们要计算 `1+2+3+…+100000` 呢。直接在合约里面写出这个表达式是不可能的。为了避免重复劳动，我们就可以用到循环。Solidity 提供了三种循环：

- 「for 循环」
- 「while 循环」
- 「do-while 循环」

本节我们将会介绍 `for` 循环。

当达到同一目的有多个不同可选方案时，往往意味着需要权衡取舍

## for 循环语法

Solidity 的 `for` 循环的语法与 C 语言，Javascript 基本相同，其语法如下：

```
for (init-statement; test-statement; iteration-statement) {
    _// 循环体 _
}
```

在 Solidity 中，for 循环是处理迭代任务的强大工具，它包含三个主要的控制语句：

- init-statement: 用于在循环开始之前初始化循环变量，这一语句仅在循环开始时执行一次。
- test-statement: 用于判断是否满足继续执行循环的条件。这个判断在每一轮循环开始前都会执行一次，如果条件不满足，则退出循环。
- iteration-statement: 用于在每轮循环的代码执行完毕后更新循环变量。这确保了在下一次迭代开始之前，循环变量的状态已经更新。

例如下面的示例中我们可以看到 `init-statement` 是 `i=1` ， `test-statement` 是 `i<=10` ， `iteration-statement` 是 `i++` 。

```
for(uint16 i = 1; i <= 10; i++) {
    _// init-statement是 i=1 ; test-statement是 i<=n ; iteration-statement是 i++_
    sum += i;
}
```

上面的例子中， `init-statement` 定义并初始化了循环变量 `i=1` 。然后 `test-statement` 则判断循环变量 `i` 是否还是小于等于 10，如果是就继续执行，如果不是就退出循环。 `iteration-statement` 则是在每轮循环给循环变量 `i` 加 1。

## for 循环示例

下面 5 个示例的逻辑都是一样的：**计算从 1 加到 n 的总和**。这些示例展示了你可以使用的 for 循环的不同形式来实现一样的功能。

下面是一个典型的 `for` 循环，计算从 1 加到 n 的总和。

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    uint16 i;
    for(i = 1; i <= n; i++) { _// init-statement是 i=1 ; test-statement是 i<=n ; iteration-statement是 i++_
        sum += i;
    }
    return sum;
}
```

在 `init-statement` 定义并初始化变量

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    for(uint16 i = 1; i <= n; i++) { _//你可以在init-statement里面定义并初始化变量i_
        sum += i;
    }
    return sum;
}
```

`init-statement` 可以移动到 `for` 循环之前

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    uint16 i = 1; _//init-statement被移动到这里了_
    for(; i <= n; i++) {
        sum += i;
    }
    return sum;
}
```

`iteration-statement` 可以移动到 `for` 循环内部

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    uint16 i = 1; _//init-statement被移动到这里了_
    for(; i <= n; ) {
        sum += i;
        i++; _// iteration-statement的i++被移到这里了_
    }
    return sum;
}
```

所有逻辑都可以在 `for` 循环的循环体里实现

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    uint16 i = 1; _//init-statement被移动到这里了_
    for(;;) { 
        if(i  n){ _// 这个条件语句实现了test-statement的功能_
            break;
        }
        sum += i;
        i++; _// iteration-statement的i++被移到这里了_
    }
    return sum;
}
```
