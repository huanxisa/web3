
在 Solidity 中，`constant` 关键字用于定义常量，即那些在编译时就确定且之后无法更改的变量。使用 `constant` 关键字可以确保一旦值被设定，就无法被意外或恶意修改，从而提高智能合约的安全性。

例如，假设你正在编写一个借贷合约，其中规定了必须维持三倍的抵押率，且这一比率预期在合约的整个生命周期内都不会变化。在这种情况下，你可以将抵押率定义为一个 `constant` 变量，如下所示：

```
uint constant ratio = 3;
```

## constant 的值必须能在编译期间确定

在 Solidity 中，使用 `constant` 关键字定义的变量必须在编译时就能确定其值。如果一个 `constant` 变量的值不能在编译期被确定，编译器将会抛出错误。因此，你不能使用运行时才能确定的普通变量来为 `constant` 变量赋值。这确保了 `constant` 变量的值是固定不变的，从而提高合约的可预测性和安全性。

简而言之，`constant` 的值必须在代码编写时就明确指定，并且在合约的整个生命周期内都不会改变。这种特性使得 `constant` 变量成为定义不变参数和合约设置的理想选择。

```
uint a = 3;
uint constant ratio = a; _// 不合法，不能用普通变量给 __constant__ 赋值_

uint constant b; _// 不合法，必须在声明时就赋值_
```

## constant 不能更改

`constant` 必须在声明的时候赋值（初始化），不能在其他地方为其赋值。

`constant` 不能更改

```
uint constant ratio = 3;

constructor() {
    ratio = 0; _// 不合法_
}

function f() public {
    ratio = 0; _// 不合法_
}
```
