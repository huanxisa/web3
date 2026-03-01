布尔类型是只有 `true` 或 `false` 两种可能取值的类型。在 Solidity 中，布尔类型变量可以使用 `bool` 关键字进行定义。

## 运算符

布尔类型可以使用的运算符和作用如下所示，运算操作后得到的结果依然是布尔类型。

- `!`  （逻辑非）
- `&&` （逻辑与）
- `||` （逻辑或 ）
- `==` （等于）
- `!=` （不等于）

```
假设 a=false , b=true
!a     // true
a && b // false
a || b // true
a == b // false
a != b // true
```

## 短路规则

需要注意的是，逻辑运算符 `||` 和 `&&` 在 Solidity 中都遵循短路规则（short-circuiting）。其规则如下：

- 对于 `f(x) || g(y)`，如果 `f(x)` 为 `true`，则 `g(y)` 不会被执行。
- 对于 `f(x) && g(y)`，如果 `f(x)` 为 `false`，则 `g(y)` 不会被执行。

**&&和 || 运算子的短路规则**

以下是一个示例，包含两个函数 `isEven` 和 `isZero`。其中，`isEven` 判断一个数是否为偶数，`isZero` 判断一个数是否为 0。如果传入的参数为 0，`isZero` 会产生副作用，使得 `zeroCount` 加 1。

```
// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract BoolShortCircuit {
    uint256 public zeroCount = 0;

    function isEven(uint256 num) private pure returns(bool) {
        return num%2 == 0;
    }

    // isZero函数有副作用，会改变状态变量zeroCount的值
    function isZero(uint256 num) private returns(bool) {
        if(num == 0) {
            zeroCount += 1; // 函数副作用，会改变zeroCount的值
        }
        return num == 0;
    }
}
```

下面的 `&&` 表达式中， `isEven(1)` 为 false，所以，有副作用的函数 `isZero(0)` 不会执行。因此，不会影响到 zeroCount 的值。

```
isEven(1) && isZero(0) _//逻辑与_
```

下面的 `&&` 表达式中， `isEven(2)` 为 true，所以会继续执行副作用函数 `isZero(0)` ，于是 `zeroCount` 会增加 1。

```
isEven(2) && isZero(0) _//逻辑与_
```

下面的 `||` 表达式中， `isEven(2)` 为 true，所以，有副作用的函数 `isZero(0)` 不会执行。因此，不会影响到 `zeroCount` 的值。

```
isEven(2) || isZero(0) _//逻辑或_
```

下面的 `||` 表达式中， `isEven(1)` 为 false，所以会继续执行副作用函数 `isZero(0)` ，于是 `zeroCount` 会增加 1。

```
isEven(1) || isZero(0) _//逻辑或_
```

## 小结

1. 布尔类型是用 `bool` 关键字定义的，只有 `true` 或 `false` 两种取值
2. 可以使用的运算符有：逻辑非(`!`), 逻辑与(`&&`), 逻辑或(`||`), 等于(`==`), 不等于(`!=`)
3. 逻辑或(`||`)和逻辑与(`&&`)都遵循短路规则，即在满足左边条件时不会再执行右边的操作
