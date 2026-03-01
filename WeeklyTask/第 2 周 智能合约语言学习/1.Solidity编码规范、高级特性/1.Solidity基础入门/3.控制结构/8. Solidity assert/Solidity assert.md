
合约执行过程中往往会出现一些异常状况，比如输入参数不合法，算术运算时除以 0，整型溢出等等。如果出现这些情况，我们就需要进行异常处理。Solidity 异常处理的统一原则是**状态回滚**（_state reverting_），也就是恢复执行前的状态，就好像什么都没有发生一样。目前 Solidity 提供了三个异常处理的函数：

- [require](https://solidity-dusky.vercel.app/docs/solidity-basic/require)
- [assert](https://solidity-dusky.vercel.app/docs/solidity-basic/assert)
- [revert](https://solidity-dusky.vercel.app/docs/solidity-basic/revert)

本节我们将会介绍 `assert` 。

Solidity 提供的 `assert` 函数让我们可以检查合约状态是否正常，否则抛出异常。

`assert` 函数通常有下面几种用途：

1. 检查不变性（invariant）：例如 ERC20 合约中，所有账户的 balance 之和应该与 totalSupply 相等
2. 防止那些不应该出现的情况出现
3. 修改合约状态后，检查合约内部状态是否符合预期

一般情况下，我们都是在函数结尾的时候使用 `assert` 来检查合约的状态。

## assert 语法

`assert` 的语法如下所示：

```
assert(condition);
```

其中 `condition` 是布尔表达式，如果其结果是 `false` 那么就会抛出异常。然后所有状态变量都会恢复原状。

例如下面的示例中，把传入的 Ether 分为两半，一半转入地址 `addr1` ，另一边转到地址 `addr2` 。在实际分账之前，使用 `require` 先检查传入的 Ether 是不是偶数。在分账完成后，使用 `assert` 检查分账前后，合约的 balance 不受影响。

ETHER 对半分账

```
function splitEther(address payable addr1, address payable addr2) public payable {
    require(msg.value % 2 == 0, "Even value required."); _// 检查传入的ether是不是偶数_
    uint balanceBeforeTransfer = address(this).balance;
    addr1.transfer(msg.value / 2);
    addr2.transfer(msg.value / 2);
    assert(address(this).balance == balanceBeforeTransfer); _// 检查分账前后，本合约的balance不受影响_
}
```

## assert 与 require 的区别

在 Solidity 中，`assert` 和 `require` 都用于检查异常情况并在条件不满足时抛出异常。虽然它们在行为上相似，主要区别在于它们的使用场景和语义意义。

- `require`: 通常用于验证外部输入、处理条件和确认合约的交互符合预期。它主要用于可恢复的错误或者在正常的业务逻辑中检查条件，比如验证用户输入、合约状态条件或执行前的检查。如果 `require` 检查失败，会撤销所有修改并退还剩余的 gas。
- `assert`: 用于检查代码逻辑中不应发生的情况，主要是内部错误，如不变量的检查或某些后置条件，这些通常指示合约存在 Bug。`assert` 应仅在确定有逻辑错误时使用，因为如果 `assert` 失败，它表示一个严重的错误，通常是编码或逻辑错误，需要马上修复。与 `require` 不同，`assert` 失败将消耗所有提供的 gas，并回滚所有修改。

使用 `require` 和 `assert` 的这种区分是一种编程惯例，有助于提高代码的清晰度和维护性。正确地使用这两者，不仅可以确保合约逻辑的正确性，还能帮助开发者更快地定位问题所在。尽管可以交替使用这两个关键字而不影响合约的功能，这样做通常会使得合约的可读性和可维护性降低。正确的使用习惯是根据错误的类型和来源来选择使用 `require` 还是 `assert`。
