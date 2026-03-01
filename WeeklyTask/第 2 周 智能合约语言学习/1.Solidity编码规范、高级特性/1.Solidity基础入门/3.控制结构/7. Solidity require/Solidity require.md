
在智能合约的执行过程中，经常会遇到各种异常情况，如输入参数非法、算术运算中的除零错误、整型溢出等。为了处理这些异常，Solidity 采用状态回滚（state reverting）的机制，即在发生异常时撤销所有执行中的改变，恢复到执行前的状态，仿佛未执行任何操作一样。Solidity 为异常处理提供了三种函数：

- require
- assert
- revert

本节主要介绍 require 函数的使用。

`require` 函数在智能合约中主要用于验证函数执行前的条件，确保合约状态的正确性。如果 `require` 的条件不满足，则函数将停止执行，并抛出异常，触发状态回滚。这种机制非常有用于以下场景：

1. 检查输入参数：验证传入函数的参数是否满足预期，确保它们在合理的范围或状态。
2. 检查操作结果：确保某些操作的结果如预期一样有效，例如，从某个函数调用返回的值。
3. 预检条件：在执行函数的主要逻辑之前，确认所有必要的条件都已经满足。

通常，`require` 语句被放置在函数的开始处，以便在进一步处理任何逻辑之前，首先确保所有基础条件都被满足。这不仅有助于防止错误或恶意的操作，还能有效地节约因执行不必要操作而浪费的 Gas。

## require 语法

`require` 的语法如下所示：

```
require(condition, "My error string");
```

在智能合约中，`require` 函数是用于处理异常情况的关键工具。它接受一个布尔表达式作为条件，如果该条件评估为 `false`，则会立即抛出异常并终止执行，同时撤销所有改变，使所有状态变量恢复到事务开始前的状态。

例如，考虑下面的用例，其中一个智能合约需要将传入的以太币（Ether）平均分配到两个不同的地址 `addr1` 和 `addr2`。在进行转账之前，我们使用 `require` 来确保传入的以太币数量是偶数，以便能够平均分配：

ETHER 对半分账

```
function splitEther(address payable addr1, address payable addr2) public payable {
    require(msg.value % 2 == 0, "Even value required."); _// 检查传入的ether是不是偶数_
    addr1.transfer(msg.value / 2);
    addr2.transfer(msg.value / 2);
}
```
