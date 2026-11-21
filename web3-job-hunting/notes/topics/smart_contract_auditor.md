# 智能合约审计师学习路径

> **定位**：从 Web2 后端 / DeFi 协议读者视角，回答「审计师到底需不需要懂 Yul/Assembly，如何系统入行」这个问题。

---

## 一、先回答核心问题：审计师需要懂 Assembly 吗？

**结论先于路径**：是的，但深度因审计类型而异。

| 审计类型 | Assembly 必要程度 | 代表场景 |
|---|---|---|
| **核心 DeFi 协议**（Uniswap / Curve / Balancer 等）| ⭐⭐⭐⭐⭐ 必须精通 | TickMath、FullMath 等核心库全是 Yul，错一个移位就是套利漏洞 |
| **通用业务合约**（NFT / Staking / Vesting）| ⭐⭐ 了解即可 | 偶有 `unchecked` 块或 bitwise 操作，大多数逻辑在 Solidity 层 |
| **Layer2 / 桥 / 跨链**（Optimism / Arbitrum 等）| ⭐⭐⭐⭐ 必须深入 | Sequencer 欺诈证明、消息编码、内存布局都依赖低级操作 |
| **ZK 电路 / Prover** | ⭐ 不涉及 EVM Assembly | 另一套数学体系（R1CS / PLONK），Assembly 在这里无效 |

**为什么 Assembly 错误比 Solidity 错误更危险**：

Solidity 编译器会自动插入：
- 整数溢出检查（`SafeMath` 逻辑内置）
- 数组越界检查
- 函数选择器合法性校验

进入 `assembly { }` 块后，**所有保护全部关闭**，等同于写裸 EVM 字节码。若逻辑有误，攻击者可以：
1. 绕过溢出检查，造成价格操纵（如 TickMath 移位错误会导致 sqrtPrice 溢出）
2. 利用错误的 slot 读写污染存储
3. 通过内存越界伪造返回数据（returndata 攻击）

---

## 二、Yul 是什么：一句话定义

**Yul** = Solidity 的内联汇编语言，语法类 C，直接操作 EVM 操作码。

```solidity
// Solidity 层（有保护）
uint256 a = x + y;  // 编译器插入溢出检查

// Assembly 层（无保护，手写 EVM 操作码）
assembly {
    let a := add(x, y)   // 直接调用 ADD 操作码，不检查溢出
}
```

---

## 三、审计师必须掌握的 Yul 核心语法

### 3.1 基本运算（对应 EVM 操作码）

| Yul 语法 | EVM 操作码 | 含义 |
|---|---|---|
| `add(a, b)` | ADD | a + b（无溢出检查）|
| `sub(a, b)` | SUB | a - b（无溢出检查）|
| `mul(a, b)` | MUL | a * b（无溢出检查，可超出 uint256 截断）|
| `div(a, b)` | DIV | a / b（整数除，b=0 时返回 0 而非 revert）|
| `mod(a, b)` | MOD | a % b |
| `exp(a, b)` | EXP | a^b（gas 极贵，审计重点）|

### 3.2 位运算（TickMath 的核心操作）

| Yul 语法 | 含义 | TickMath 中的用途 |
|---|---|---|
| `shl(n, x)` | x << n（左移 n 位，相当于 x × 2ⁿ）| 把 1 扩展成对应位权重（如 `shl(7, 1)` = 128）|
| `shr(n, x)` | x >> n（右移 n 位，相当于 x / 2ⁿ）| 提取最高位、归一化定点数 |
| `or(a, b)` | a \| b（按位 OR）| 累积 MSB 位和 log₂ 小数位 |
| `and(a, b)` | a & b（按位 AND）| 提取特定位 |
| `not(a)` | ~a（按位取反）| |
| `xor(a, b)` | a ^ b（按位 XOR）| |

### 3.3 比较运算

| Yul 语法 | 含义 | 返回值 |
|---|---|---|
| `gt(a, b)` | a > b | 1 或 0（**不是 bool**，是 uint256）|
| `lt(a, b)` | a < b | 1 或 0 |
| `eq(a, b)` | a == b | 1 或 0 |
| `iszero(a)` | a == 0 | 1 或 0 |

> **审计关键点**：`gt`/`lt` 返回整数，可以直接参与算术。`shl(7, gt(r, x))` 是 TickMath 中一个常见惯用写法——用比较结果驱动位移量，等价于一个无分支的 `if`，审计时必须理解这种模式。

### 3.4 内存与存储操作（安全高风险区）

| Yul 语法 | 含义 | 审计风险 |
|---|---|---|
| `mload(ptr)` | 从内存地址 ptr 读 32 字节 | 越界读：ptr 错误可读到任意内存 |
| `mstore(ptr, val)` | 向 ptr 写 32 字节 | 越界写：ptr 错误可覆盖返回数据、函数选择器 |
| `mstore8(ptr, val)` | 向 ptr 写 1 字节 | |
| `sload(slot)` | 从存储 slot 读 | slot 计算错误 → 读到错误状态 |
| `sstore(slot, val)` | 向存储 slot 写 | slot 计算错误 → 状态污染，存储碰撞 |

### 3.5 控制流

```yul
// 声明变量（只在 assembly 块内有效）
let x := 0
let result := mul(a, b)

// 条件（没有 else）
if gt(x, 0) {
    x := sub(x, 1)
}

// 循环
for { let i := 0 } lt(i, 10) { i := add(i, 1) } {
    // body
}

// 函数（只在 assembly 块内）
function double(x) -> result {
    result := mul(x, 2)
}
```

### 3.6 调用相关（合约交互高风险区）

| Yul 语法 | 含义 | 审计风险 |
|---|---|---|
| `call(gas, to, value, inOffset, inSize, outOffset, outSize)` | 调用外部合约 | 返回值未检查、重入 |
| `delegatecall(gas, to, ...)` | delegatecall（共享存储）| 升级代理中最危险的操作 |
| `staticcall(gas, to, ...)` | 只读调用 | |
| `returndatasize()` | 获取上次调用返回数据长度 | returndata 伪造攻击 |
| `returndatacopy(dest, src, len)` | 拷贝返回数据 | |

---

## 四、TickMath.sol 中的 Yul 模式（逐一剖析）

以 `getTickAtSqrtRatio` 为例，审计师需要识别并验证的四种模式：

### 模式 1：无分支条件赋值

```solidity
let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
msb := or(msb, f)
r := shr(f, r)
```

等价 Solidity：
```solidity
uint f = r > type(uint128).max ? 128 : 0;
msb |= f;
r >>= f;
```

**审计验证点**：
- `gt` 返回值是 0 或 1，`shl(7, 1)` = 128，`shl(7, 0)` = 0 ✓
- `shr(128, r)` 消掉高 128 位 ✓
- 8 轮之后 msb 是否覆盖所有情况（0–255）✓

### 模式 2：定点数平方归一化

```solidity
r := shr(127, mul(r, r))
let f := shr(128, r)
log_2 := or(log_2, shl(63, f))
r := shr(f, r)
```

**审计验证点**：
- `r < 2^128`，所以 `mul(r, r) < 2^256`（不溢出 uint256）✓
- `shr(127, r²)` = r² / 2^127，保持 r 在 \([2^{127}, 2^{129})\) 范围 ✓
- `shr(128, r)` 提取最高位（0 或 1）✓
- 14 轮重复，位权从 63 递减到 50，确认无跳位 ✓

### 模式 3：有符号整数的 `>> 128`

```solidity
int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
```

**审计验证点**：
- 这是 **Solidity 层**（不是 assembly），但审计师需验证：有符号整数右移是**算术移位**（保留符号位），负数除以 2^128 不会截断成正数 ✓
- `int24` 强制转换是否有截断风险：tick 范围 `[-887272, 887272]`，int24 范围 `[-8388608, 8388607]`，不会截断 ✓

### 模式 4：最终反查验证

```solidity
tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
```

**审计验证点**：
- 反查是为了补偿 14 位精度误差，这是正确的防御策略 ✓
- 若 tickHi 合法（其 sqrt ratio ≤ 输入），返回 tickHi（更大的 floor 值）✓
- 是否存在无限循环？不会，`getSqrtRatioAtTick` 是纯计算，无外部调用 ✓

---

## 五、审计师学习路线图（12–16 周）

### 第一阶段：Solidity 安全基础（1–3 周）

**目标**：掌握 Solidity 层的常见漏洞模式。

| 资源 | 类型 | 重点 |
|---|---|---|
| [Solidity 官方文档](https://docs.soliditylang.org/) | 文档 | Assembly / Storage Layout / ABI Encoding |
| [Secureum Bootcamp Mind Map](https://github.com/x676f64/secureum-mind_x) | 笔记 | 200 个安全考点汇总，审计备考必读 |
| [SWC Registry](https://swcregistry.io/) | 漏洞数据库 | 智能合约漏洞分类标准（类似 CVE） |
| [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/) | CTF 实战 | 18 关从重入到闪电贷，每关对应一类漏洞 |
| [Ethernaut (OpenZeppelin)](https://ethernaut.openzeppelin.com/) | CTF 实战 | 32 关，Solidity 漏洞入门经典 |

**本阶段产出**：Ethernaut 前 15 关 + Damn Vulnerable DeFi 前 8 关全部独立通关。

---

### 第二阶段：EVM 深度 + Yul Assembly（4–6 周）

**目标**：理解 EVM 执行模型，能读写 Yul assembly，能验证算术正确性。

| 资源 | 类型 | 重点 |
|---|---|---|
| [EVM Codes](https://www.evm.codes/) | 交互式参考 | 每个 opcode 的 gas cost、stack 效果、可视化执行 |
| [Ethereum Yellow Paper](https://ethereum.github.io/yellowpaper/paper.pdf) | 原始规范 | EVM 正式定义（审计时的"法律文本"）|
| [Yul 官方规范](https://docs.soliditylang.org/en/latest/yul.html) | 文档 | 完整语法和语义 |
| [Huff Language](https://huff.sh/) | 工具 | 纯 EVM 汇编语言，强迫你理解 stack 操作顺序 |
| [evm.codes/playground](https://www.evm.codes/playground) | 调试工具 | 单步执行 EVM 字节码 |
| [Understanding EVM Assembly](https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-i-introduction-832efd2d7737/) | OpenZeppelin 博客系列 | 从 Solidity → 字节码完整拆解（6 篇）|

**本阶段核心练习**：

1. 手写一个 `Math.sol`，只用 Yul 实现 `mulDiv`（uint256 乘除不溢出），与 [FullMath.sol](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/FullMath.sol) 对比
2. 用 `evm.codes/playground` 单步跟踪 `getTickAtSqrtRatio` 的某一次调用
3. 阅读并注释 [Uniswap v3 TickMath.sol](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol) 每一行（本文档已完成）

---

### 第三阶段：真实审计方法论（7–10 周）

**目标**：建立系统化审计流程，能独立产出审计报告。

| 资源 | 类型 | 重点 |
|---|---|---|
| [Trail of Bits 审计报告](https://github.com/trailofbits/publications#smart-contract-audits) | 真实报告 | 行业顶级，逐份分析漏洞发现思路 |
| [Consensys Diligence 报告](https://consensys.io/diligence/audits/) | 真实报告 | 标准报告格式参考 |
| [Code4rena 归档](https://code4rena.com/reports) | 比赛报告 | 社区审计模式，大量中低危漏洞实例 |
| [Sherlock 归档](https://app.sherlock.xyz/audits/contests) | 比赛报告 | 经济模型类漏洞集中 |
| [Cyfrin Updraft](https://updraft.cyfrin.io/) | 视频课程 | 免费，Patrick Collins 出品，覆盖高级漏洞 |
| [How to Audit a Smart Contract](https://medium.com/coinmonks/how-to-audit-a-smart-contract-most-dangerous-attacks-in-solidity-ae402a7e7868) | 文章 | 5 种最危险攻击的审计 checklist |

**审计流程标准（每次审计必须执行）**：

```
1. 理解协议业务逻辑（2–4 小时阅读文档、白皮书）
2. 绘制合约调用图（Surya / sol2uml 工具）
3. 通读代码，标注可信/不可信输入边界
4. 逐函数验证以下清单：
   - [ ] 整数溢出（重点：assembly 块、unchecked 块）
   - [ ] 重入（check-effect-interaction 顺序）
   - [ ] 访问控制（onlyOwner / role 是否正确）
   - [ ] 闪电贷操纵（价格预言机的时间锁）
   - [ ] 精度损失（除法顺序、舍入方向）
   - [ ] 边界条件（min/max tick、零流动性、单 tick 池）
5. 编写 PoC（Foundry fuzzing + 手工测试）
6. 撰写报告（严重度分级：Critical / High / Medium / Low / Informational）
```

---

### 第四阶段：专项 DeFi 协议深度（11–16 周）

**目标**：能独立审计某一类 DeFi 协议（AMM / 借贷 / 衍生品）。

| 协议类型 | 推荐阅读代码 | 核心审计关注点 |
|---|---|---|
| **AMM（恒定乘积）** | Uniswap v2-core / v3-core | sqrtPrice 溢出、tick 边界、流动性计算精度 |
| **借贷协议** | Aave v3 / Compound v3 | 清算健康因子、利率模型精度、闪电贷 |
| **衍生品 / 永续合约** | GMX v2 / dYdX | 资金费率计算、价格操纵防护、仓位强平 |
| **跨链桥** | Optimism Bridge / Wormhole | 消息验证、重放攻击、重入 |
| **稳定币** | Curve 3pool / Frax | AMM 不变量、算法稳定机制、挤兑 |

---

## 六、工具链

| 工具 | 用途 | 安装 |
|---|---|---|
| **Foundry** | 测试框架、fuzzing、PoC 编写 | `curl -L https://foundry.paradigm.xyz \| bash` |
| **Slither** | 静态分析，自动发现常见漏洞 | `pip install slither-analyzer` |
| **Mythril** | 符号执行，自动发现逻辑漏洞 | `pip install mythril` |
| **Echidna** | 属性测试（fuzzing）| Homebrew 安装 |
| **Surya** | 合约调用图可视化 | `npm install -g surya` |
| **sol2uml** | UML 类图 | `npm install -g sol2uml` |
| **Tenderly** | 线上交易调试、事件回放 | 网页版，免费 |
| **Phalcon Explorer** | DeFi 黑客事件 attack trace 分析 | 网页版，免费 |

---

## 七、入行路径：如何开始接到第一笔审计单

### 路径 A：竞赛起步（推荐，0 成本）

1. 在 [Code4rena](https://code4rena.com/) 或 [Sherlock](https://app.sherlock.xyz/) 注册
2. 参与公开竞赛（每次 1–2 周），提交发现的漏洞
3. 积累排名和奖励历史，形成公开的审计履历
4. 3–5 次竞赛后，头部审计机构会主动联系

### 路径 B：机构实习（需要推荐信或 GitHub 作品集）

| 机构 | 风格 | 联系方式 |
|---|---|---|
| **Trail of Bits** | 最高端，形式化验证 | 官网申请 |
| **OpenZeppelin** | 以太坊生态权威 | 官网申请 |
| **Consensys Diligence** | 以太坊基金会背景 | 官网申请 |
| **Spearbit** | 去中心化审计网络 | 竞赛排名后受邀 |
| **Cyfrin** | 新兴，中文社区友好 | Discord |
| **Secure3** | 中文团队，华人审计师多 | Discord |

### 路径 C：独立审计 / 协议内部安全岗

适合有足够竞赛记录后，直接加入协议方的安全团队（Uniswap、Aave 等都有内部安全工程师岗位）。

---

## 八、与本项目的关系

| 学习路径 | 与主线关联 |
|---|---|
| Uniswap v3-core 代码阅读（正在进行）| 审计 AMM 的最佳实践素材，TickMath / FullMath 是典型 Assembly 案例 |
| 套利与 MEV 专题 | 审计视角：了解攻击者的经济激励，有助于发现经济模型漏洞 |
| Solidity 合约方向（主线 B）| 初级审计师的技能和业务合约工程师高度重叠，L2 级别岗位可以兼顾 |

---

## 参考资料汇总

- [Solidity Yul 规范](https://docs.soliditylang.org/en/latest/yul.html)
- [EVM Codes 交互参考](https://www.evm.codes/)
- [Secureum Bootcamp Mind Map](https://github.com/x676f64/secureum-mind_x)
- [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)
- [Ethernaut](https://ethernaut.openzeppelin.com/)
- [Trail of Bits 公开审计报告](https://github.com/trailofbits/publications)
- [Code4rena 竞赛平台](https://code4rena.com/)
- [Sherlock 竞赛平台](https://app.sherlock.xyz/)
- [Cyfrin Updraft 免费课程](https://updraft.cyfrin.io/)
- [OpenZeppelin 合约解构系列博客](https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-i-introduction-832efd2d7737/)
- [Uniswap v3-core TickMath.sol](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol)
