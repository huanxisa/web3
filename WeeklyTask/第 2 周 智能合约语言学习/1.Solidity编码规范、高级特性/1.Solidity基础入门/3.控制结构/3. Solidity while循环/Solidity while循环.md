
想象一下，如果我们要计算 `1+2+3` 的和，这很简单：

```
uint256 sum = 1+2+3;
```

但是如果我们要计算 `1+2+3+…+100000` 呢。直接在合约里面写出这个表达式是不可能的。为了避免重复劳动，我们就可以用到循环。Solidity 提供了三种循环：

- [「for 循环」](https://solidity-dusky.vercel.app/docs/solidity-basic/for)
- [「while 循环」](https://solidity-dusky.vercel.app/docs/solidity-basic/while)
- [「do-while 循环」](https://solidity-dusky.vercel.app/docs/solidity-basic/do-while)

本节我们将会介绍 `while` 循环。

## while 循环语法

Solidity 的 `while` 循环的语法与 C 语言，Javascript 基本相同，其语法如下：

```
while (test-statement) {
    _// 循环体_
}
```

我们可以看到 while 循环里面有两个表达式：

- **test-statement**
- **循环体**

在 Solidity 中，`while` 循环是一个在满足特定条件时重复执行代码块的控制结构。它在每次循环迭代开始前，首先评估一个测试语句（test-statement）：

- 如果 test-statement 评估为 `true`，则执行循环体内的代码。
- 如果 test-statement 评估为 `false`，循环将终止，控制流将转移到循环体后的代码。

使用 `while` 循环时，通常需要在循环体内部对控制变量进行修改，以确保在某个条件下，测试语句最终将返回 `false`，从而避免无限循环的发生。这种循环特别适用于那些在循环开始前不知道需要执行多少次迭代的情况。

## for 循环与 while 循环的比较

如果你有先学习了我们的 `for` 循环教程，你应该会留意到其中有一个示例展示了 `for` 循环的控制语句里面只剩下 `test-statement` ，如下面所示：

`for` 循环，从 1 加到 N

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    uint16 i = 1; 
    for(; i <= n; ) { _// 循环控制语句只剩下test-statement: i <= n_
        sum += i;
        i++; _// 修改循环变量的值_
    }
    return sum;
}
```

其实这种形式就类似于 `while` 循环，我们可以稍作修改就变成 `while` 循环：

`while` 循环，从 1 加到 N

```
function sumToN(uint16 n) public pure returns(uint16) {
    uint16 sum = 0;
    uint16 i = 1; 
    while(i <= n) { _//只改了这一行_
        sum += i;
        i++; _// 修改循环变量的值_
    }
    return sum;
}
```

在编程中选择使用 `for` 循环还是 `while` 循环，并没有严格的规定。选择哪一种循环结构主要取决于哪种方式可以让代码更加整洁和易于理解。不同的编程场景可能需要不同类型的循环。

以下是一些通常的做法，但请注意这些不是强制性的规定：

- 使用 `for` 循环：如果你有明确的初始条件和终止条件，`for` 循环通常是更好的选择。这是因为 `for` 循环可以在一个地方集中处理这些元素，使得代码更加清晰和直观。
- 使用 `while` 循环：如果没有明确的初始和终止条件，或者当测试语句（test-statement）的条件判断较为复杂时，`while` 循环可能是更合适的选择。`while` 循环便于处理那些需要持续检查条件是否成立才能执行的情况。

有明确的初始和终止条件，使用 `for` 循环

```
for(uint16 i = 1; i <= n; i++) {
    _// 代码块_
}
```

没有明确的初始和终止条件，条件判断较复杂，使用 `while` 循环

```
while(isEven(x) && !isZero(x)) {
    _// 代码块_
}
```
