在Solidity中，声明「引用类型」时必须指定数据位置（data location），这是为了明确变量的存储方式和生命周期。例如，声明一个动态数组时，你可能会使用 uint[] storage。重要的是要注意，虽然通常必须指定数据位置，但声明状态变量时则不需要这样做，因为状态变量默认存储在 storage。
在函数内部声明引用类型时必须指定数据位置，常见的数据位置有三种：
- storage：数据永久存储在区块链上，其生命周期与合约本身一致。
- memory：数据暂时存储在内存中，是易失的，其生命周期仅限于函数调用期间。
- calldata：类似于 memory，但用于存放函数参数，与 memory 不同的是，calldata 中的数据不可修改且相比 memory 更节省 gas。
storage 可以类比为硬盘，而 memory 可类比为 RAM。calldata 可能稍显陌生，它的独特之处在于其不可变性和高效的 gas 使用。因其特性，当引用类型的函数参数不需要修改时，推荐使用 calldata 而非 memory。
为了避免过度复杂化，我们将在「Solidity进阶」中更深入地讨论 calldata 与 memory 的差异。目前，只需了解上述关于 calldata 的基本差异即可：仅用于函数参数，数据不可更改，是易失的，并且比 memory 更节约 gas。这些理解将帮助你更有效地使用Solidity中的数据位置。