
合约执行过程中往往会出现一些异常状况，比如输入参数不合法，算术运算时除以 0，整型溢出等等。如果出现这些情况，我们就需要进行异常处理。Solidity 异常处理的统一原则是**状态回滚**（_state reverting_），也就是恢复执行前的状态，就好像什么都没有发生一样。目前 Solidity 提供了三个异常处理的函数：

- [require](https://solidity-dusky.vercel.app/docs/solidity-basic/require)
- [assert](https://solidity-dusky.vercel.app/docs/solidity-basic/assert)
- [revert](https://solidity-dusky.vercel.app/docs/solidity-basic/revert)

本节我们将会介绍 `revert` 。

在 Solidity 中，`revert` 与 `require` 功能上有些相似，它们都用于异常处理并撤销所有状态变化。然而，`revert` 的使用更为直接：它不像 `require` 那样进行条件检查，而是立即抛出异常。这使得 `revert` 非常适用于那些需要立即中止执行并恢复合约到执行前状态的场景。

`revert` 的灵活性表现在它可以与 `if-else` 语句结合使用，提供比 `require` 更精细的控制逻辑。例如，在一些复杂的逻辑判断中，使用 `revert` 加上 `if-else` 结构可以根据多个条件决定是否应该终止执行。这种方法虽然在表达能力上非常强，但可能牺牲一些代码的直观性和易读性，这是在使用时需要考虑的一个权衡点。

## revert 语法

`revert` 的语法如下所示：

`revert` 使用方式

```
_// 使用方式一_
revert CustomError(arg1, arg2);

_// 使用方式二_
revert("My Error string");
```

其中 `CustomError` 是自定义的 Error

例如下面的示例中，把传入的 Ether 分为两半，一半转入地址 `addr1` ，另一边转到地址 `addr2` 。在实际分账之前，使用 `revert` 先检查传入的 Ether 是不是偶数。

ETHER 对半分账

```
function splitEther(address payable addr1, address payable addr2) public payable {
    if (msg.value % 2 == 0) { _// 检查传入的ether是不是偶数_
        revert("Even value revertd.");
    } 
    addr1.transfer(msg.value / 2);
    addr2.transfer(msg.value / 2);
}
```

## revert 与 require 的区别

在前面的讨论中，我们提到了 `revert` 可以在某些复杂的情况下替代 `require` 来停止执行并抛出异常。这里，我们将展示两种表达方式在功能上是等价的，但各自适用于不同的编程风格和场景。

`require` 与 `revert` 的等价表达式

判断是否是偶数

```
require(msg.value % 2 == 0, "Even value revertd.");
```

等价于：

```
if (msg.value % 2 == 0) {
    revert("Even value revertd.");
}
```

在一些复杂的逻辑嵌套中，使用 `revert` 会更加方便，清晰：

```
if(condition1) {
    _// 可能有更多的 if-else 嵌套_
    if(condition2) {
        _// do something_
    } 
    revert("condition2 not fulfilled");
}
```
