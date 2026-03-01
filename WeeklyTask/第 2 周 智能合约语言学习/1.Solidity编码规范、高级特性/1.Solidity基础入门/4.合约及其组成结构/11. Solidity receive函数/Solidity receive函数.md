
`receive` 函数是 Solidity 中的一种特殊函数，主要用于接收以太币（Ether）的转账。此外，还有一个 `fallback` 函数也可以用来接收以太币转账，我们将在下一节详细介绍。

需要注意的是，以太币转账与 ERC20 代币转账之间存在本质区别：

- 以太币转账：转账的是以太坊的原生代币（native token），即 Ether。
- ERC20 代币转账：转账的是非原生代币（non-native token），这些代币在合约内部实现类似于一个数据库，记录了每个持有者的代币数量。ERC20 代币转账通过调用普通的合约函数来实现。

## Solidity receive 函数定义语法

`receive` 函数的定义格式是固定的，其可见性（_visibility_）必须为 `external`，状态可变性（_state mutability_）必须为 `payable`。同时要注意 `receive` 函数不需要 `function` 前缀

```
receive() external payable {
    _// 函数体_
}
```

## 合约没有定义 receive 和 fallback 函数时，不能对其转账

如果一个合约既没有定义 `receive` 函数，也没有定义 `fallback` 函数，那么该合约将无法接收以太币转账。在这种情况下，所有试图向该合约进行的转账操作都会被 revert（回退）。如下面所示：

`Callee` 没有定义 `receive` 和 `fallback` 函数，三种对其转账的方法都失败

```
_// SPDX-License-Identifier: GPL-3.0_

pragma solidity ^0.8.17;

_// Callee既没有定义receive函数，也没有定义fallback函数_
contract Callee {}

contract Caller {
    address payable callee;

    _// 注意： 记得在部署的时候给 Caller 合约转账一些 Wei，比如 100_
    constructor() payable{
        callee = payable(address(new Callee()));
    }

    _// 失败，因为Callee既没有定义receive函数，也没有定义fallback函数_
    function tryTransfer() external {
        callee.transfer(1);
    }

    _// 失败，因为Callee既没有定义receive函数，也没有定义fallback函数_
    function trySend() external {
        bool success = callee.send(1);
        require(success, "Failed to send Ether");
    }

    _// 失败，因为Callee既没有定义receive函数，也没有定义fallback函数_
    function tryCall() external {
        (bool success, bytes memory data) = callee.call{value: 1}("");
        require(success, "Failed to send Ether");
    }
}
```

需要注意的是，我们提到的以太币转账指的是纯转账（`msg.data` 为空）。这种转账不会调用任何函数，只是将以太币转到目标地址。在 Solidity 中，有三种方法可以进行以太币转账：

- `send(amount)`：发送 `amount` 数量的以太币，固定使用 2300 gas，错误时不会 revert，只返回布尔值表示成功或失败。
- `transfer(amount)`：发送 `amount` 数量的以太币，固定使用 2300 gas，错误时会 revert。
- `call{value: amount}("")`：发送 `amount` 数量的以太币，gas 可以自由设定，返回布尔值表示成功或失败。

这三种方法都是将 `amount` 数量的以太币发送到目标地址。如果合约既没有定义 `receive` 函数，也没有定义 `fallback` 函数，那么进行纯转账的操作会失败并回退。但是，这种限制不影响带有 `msg.data` 的普通函数调用。例如，可以使用 `call` 来调用普通函数：

```
_// 调用 foo() 函数 _
call( abi.encodeWithSignature("foo()") );

_// 调用 foo() 函数，并转账 1 Wei _
call{value: 1}( abi.encodeWithSignature("foo()") );
```

注意第二个函数调用中，还同时向目标合约转了 1 Wei， 这也是允许的，因为这是一个普通函数调用，而不是纯转账。

## 注意 Gas 不足的问题

在定义 `receive` 函数时，需要特别注意 Gas 不足的问题。前面我们提到，`send` 和 `transfer` 方法的 Gas 是固定为 2300 的。因此，这些方法剩余的 Gas 往往不足以执行复杂操作。如果 `receive` 函数体需要执行较复杂的操作，那么可能会抛出“Out of Gas”异常。

以下操作通常会消耗超过 2300 Gas：

- 修改状态变量
- 创建合约
- 调用其他相对复杂的函数
- 发送以太币到其他账户

例如，下面的 `receive` 函数由于消耗的 Gas 超过了 2300，因此它总是会被 revert：

`receive` 函数消耗过多 GAS

```
_// 用send,transfer函数转账到该合约都会被 revert_
_// 原因是消耗的 Gas 超过了 2300_
contract Example {
    uint a;
    receive() external payable {
        a += 1;
    }
}
```
