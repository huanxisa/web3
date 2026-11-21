# Uniswap V3 公式完整推导

---

## 一、从 V2 的恒定乘积出发

### 1.1 V2 基础公式

V2 的核心约束是：

$$x \cdot y = k$$

其中：
- $x$ = token0 的储备量（如 ETH）
- $y$ = token1 的储备量（如 USDC）
- $k$ = 常数（每次 swap 前后保持不变，手续费暂忽略）

**价格定义：**

$$P = \frac{y}{x}$$

即：买 1 个 token0 需要花多少 token1（USDC/ETH）

---

### 1.2 V2 的问题

设当前价格为 $P_c$，实际交易发生的价格范围很窄（如 $P_c \pm 5\%$），但流动性铺满了 $(0, +\infty)$，大量资金永远用不上，资金利用率极低。

---

## 二、V3 集中流动性的数学构造

### 2.1 核心思路

V3 的想法：让 LP 只在 $[P_a, P_b]$ 区间内提供流动性。

区间之外，LP 的仓位不再参与交易，全部转换为单一资产持有。

- 价格超过上界 $P_b$：全部持有 token1（USDC）
- 价格低于下界 $P_a$：全部持有 token0（ETH）

---

### 2.2 引入虚拟储备（Virtual Reserves）

**关键推导：**

真实储备 $(x_{real}, y_{real})$ 在区间边界处满足：

- 当 $P = P_b$ 时：$x_{real} = 0$（token0 全部卖出）
- 当 $P = P_a$ 时：$y_{real} = 0$（token1 全部卖出）

为了让区间内的行为满足恒定乘积，定义**虚拟储备**：

$$x_{virtual} = x_{real} + x_{offset}$$

$$y_{virtual} = y_{real} + y_{offset}$$

使得虚拟储备满足：

$$x_{virtual} \cdot y_{virtual} = k$$

**确定 offset 的值：**

当 $P = P_b$ 时，$x_{real} = 0$，此时：

$$x_{virtual} = x_{offset}$$

又因为 $P_b = \frac{y_{virtual}}{x_{virtual}}$，所以 $y_{virtual} = P_b \cdot x_{offset}$

代入恒定乘积：

$$x_{offset} \cdot P_b \cdot x_{offset} = k$$

$$x_{offset}^2 = \frac{k}{P_b}$$

$$x_{offset} = \sqrt{\frac{k}{P_b}} = \frac{\sqrt{k}}{\sqrt{P_b}}$$

同理，当 $P = P_a$ 时，$y_{real} = 0$，此时：

$$y_{virtual} = y_{offset}$$

$$P_a = \frac{y_{offset}}{x_{virtual}}$$，所以 $x_{virtual} = \frac{y_{offset}}{P_a}$

代入恒定乘积：

$$\frac{y_{offset}}{P_a} \cdot y_{offset} = k$$

$$y_{offset}^2 = k \cdot P_a$$

$$y_{offset} = \sqrt{k \cdot P_a} = \sqrt{k} \cdot \sqrt{P_a}$$

---

### 2.3 引入流动性 L

定义 $L = \sqrt{k}$，则：

$$x_{offset} = \frac{L}{\sqrt{P_b}}$$

$$y_{offset} = L \cdot \sqrt{P_a}$$

完整的虚拟储备恒定乘积公式：

$$\left(x_{real} + \frac{L}{\sqrt{P_b}}\right) \cdot \left(y_{real} + L\sqrt{P_a}\right) = L^2$$

**这就是 V3 白皮书的核心公式，现在你知道它是怎么来的了。**

---

## 三、从 L 推导储备量公式

### 3.1 $x_{real}$ 和 $\sqrt{P}$ 的关系

在区间 $[P_a, P_b]$ 内，当前价格为 $P$，由虚拟储备关系：

$$\sqrt{P} = \frac{y_{virtual}}{x_{virtual}} \cdot \frac{1}{\sqrt{P}}$$

更直接地，由 $y_{virtual} = L \cdot \sqrt{P}$ 和 $x_{virtual} = \frac{L}{\sqrt{P}}$（这是虚拟储备在任意价格 $P$ 下的表达），推导如下：

虚拟恒定乘积：

$$x_{virtual} \cdot y_{virtual} = L^2$$

$$\frac{L}{\sqrt{P}} \cdot L\sqrt{P} = L^2 \quad \checkmark$$

因此：

$$x_{real} = x_{virtual} - \frac{L}{\sqrt{P_b}} = \frac{L}{\sqrt{P}} - \frac{L}{\sqrt{P_b}} = L\left(\frac{1}{\sqrt{P}} - \frac{1}{\sqrt{P_b}}\right)$$

$$y_{real} = y_{virtual} - L\sqrt{P_a} = L\sqrt{P} - L\sqrt{P_a} = L\left(\sqrt{P} - \sqrt{P_a}\right)$$

---

### 3.2 边界验证

**当 $P = P_b$（价格到达上界）：**

$$x_{real} = L\left(\frac{1}{\sqrt{P_b}} - \frac{1}{\sqrt{P_b}}\right) = 0 \quad \checkmark$$

**当 $P = P_a$（价格到达下界）：**

$$y_{real} = L\left(\sqrt{P_a} - \sqrt{P_a}\right) = 0 \quad \checkmark$$

两个边界条件都满足，推导正确。

---

## 四、推导 Swap 计算公式

### 4.1 用 $\Delta y$ 换 $\Delta x$（输入 token1，输出 token0）

**已知：** 输入 $\Delta y$ 个 token1，求输出多少 token0

swap 前后，$L$ 不变（同一个区间内），价格从 $P$ 变为 $P'$

**由 $y_{real}$ 公式：**

$$y_{real} = L(\sqrt{P} - \sqrt{P_a})$$

输入 $\Delta y$ 后，新的 $y_{real}' = y_{real} + \Delta y$，对应新价格 $P'$：

$$y_{real} + \Delta y = L(\sqrt{P'} - \sqrt{P_a})$$

两式相减：

$$\Delta y = L(\sqrt{P'} - \sqrt{P_a}) - L(\sqrt{P} - \sqrt{P_a}) = L(\sqrt{P'} - \sqrt{P})$$

所以：

$$\boxed{\Delta y = L \cdot (\sqrt{P'} - \sqrt{P})}$$

变换得到新价格：

$$\boxed{\sqrt{P'} = \sqrt{P} + \frac{\Delta y}{L}}$$

**由 $x_{real}$ 公式得输出的 token0：**

$$\Delta x = x_{real} - x_{real}' = L\left(\frac{1}{\sqrt{P}} - \frac{1}{\sqrt{P_b}}\right) - L\left(\frac{1}{\sqrt{P'}} - \frac{1}{\sqrt{P_b}}\right)$$

$$\boxed{\Delta x = L\left(\frac{1}{\sqrt{P}} - \frac{1}{\sqrt{P'}}\right)}$$

---

### 4.2 用 $\Delta x$ 换 $\Delta y$（输入 token0，输出 token1）

同理，输入 $\Delta x$ 个 token0，价格从 $P$ 下降到 $P'$（$P' < P$）

$$\Delta x = L\left(\frac{1}{\sqrt{P'}} - \frac{1}{\sqrt{P}}\right)$$

$$\frac{1}{\sqrt{P'}} = \frac{1}{\sqrt{P}} + \frac{\Delta x}{L}$$

$$\boxed{\sqrt{P'} = \frac{\sqrt{P} \cdot L}{L + \Delta x \cdot \sqrt{P}}}$$

输出的 token1：

$$\boxed{\Delta y = L \cdot (\sqrt{P} - \sqrt{P'})}$$

---

## 五、推导 LP 添加流动性公式

### 5.1 给定 $L$，如何确定需要存入多少 token？

由储备量公式：

$$x_{real} = L\left(\frac{1}{\sqrt{P}} - \frac{1}{\sqrt{P_b}}\right)$$

$$y_{real} = L\left(\sqrt{P} - \sqrt{P_a}\right)$$

**反过来，给定 $\Delta x$（想存入多少 token0）求 $L$：**

$$L = \frac{\Delta x}{\dfrac{1}{\sqrt{P}} - \dfrac{1}{\sqrt{P_b}}}$$

**给定 $\Delta y$（想存入多少 token1）求 $L$：**

$$L = \frac{\Delta y}{\sqrt{P} - \sqrt{P_a}}$$

**两个公式算出来的 $L$ 必须相同**，否则说明投入比例不对，合约会自动用较小的 $L$ 并退回多余部分。

---

### 5.2 为什么两个 L 可能不同？

因为当前价格在区间内的位置决定了 x 和 y 的比例：

- 价格越靠近 $P_b$（上界），需要越多的 token1，越少的 token0
- 价格越靠近 $P_a$（下界），需要越多的 token0，越少的 token1

如果你按任意比例投入，就会有一种 token 多余。

**正确的投入比例：**

$$\frac{\Delta x}{\Delta y} = \frac{\dfrac{1}{\sqrt{P}} - \dfrac{1}{\sqrt{P_b}}}{\sqrt{P} - \sqrt{P_a}}$$

---

## 六、Tick 系统的数学推导

### 6.1 为什么用 Tick？

价格是连续的，合约无法存储连续值。V3 将价格空间离散化：

$$P(i) = 1.0001^i$$

其中 $i$ 是整数，称为 **Tick**。

**取对数得：**

$$i = \log_{1.0001} P = \frac{\ln P}{\ln 1.0001}$$

**相邻 Tick 之间的价格差：**

$$\frac{P(i+1)}{P(i)} = 1.0001$$

即每个 Tick 代表价格变化 **0.01%**（1 个基点）。

---

### 6.2 sqrtPriceX96 的推导

Solidity 不支持浮点数，合约存储的是：

$$\text{sqrtPriceX96} = \sqrt{P} \times 2^{96}$$

**为什么是 $2^{96}$？**

- $\sqrt{P}$ 是浮点数，无法直接存储
- 乘以 $2^{96}$ 将其转为定点数（Q64.96 格式）
- 高 64 位存整数部分，低 96 位存小数部分
- 既保证足够的精度，又不超过 uint256 的上限

**还原价格：**

$$P = \left(\frac{\text{sqrtPriceX96}}{2^{96}}\right)^2$$

---

## 七、无常损失的推导

### 7.1 V2 无常损失公式

设初始价格 $P_0$，变化后价格 $P_1 = r \cdot P_0$（$r$ 为价格变化比）

**持有不动（HODL）的价值：**

$$V_{hodl} = x_0 \cdot P_1 + y_0 = x_0 \cdot r P_0 + x_0 P_0 = x_0 P_0 (r + 1)$$

**提供流动性后的价值：**

价格变化后，新储备为 $x_1 = \frac{x_0}{\sqrt{r}}$，$y_1 = y_0 \cdot \sqrt{r}$

$$V_{LP} = x_1 \cdot P_1 + y_1 = \frac{x_0}{\sqrt{r}} \cdot rP_0 + x_0 P_0 \sqrt{r} = 2x_0 P_0 \sqrt{r}$$

**无常损失：**

$$IL = \frac{V_{LP}}{V_{hodl}} - 1 = \frac{2\sqrt{r}}{r+1} - 1$$

| 价格变化 $r$ | $\frac{2\sqrt{r}}{r+1}$ | 无常损失 |
|------------|------------------------|---------|
| 1.0（不变） | 1.0 | 0% |
| 1.25（+25%） | 0.9938 | -0.62% |
| 1.5（+50%） | 0.9798 | -2.02% |
| 2.0（+100%） | 0.9428 | -5.72% |
| 0.5（-50%） | 0.9428 | -5.72% |

---

### 7.2 V3 无常损失放大原理

V3 中 LP 只在 $[P_a, P_b]$ 区间内活跃，等效于用更少的资金模拟了相同的流动性深度。

**放大倍数（资金利用率）：**

$$\text{倍数} = \frac{\sqrt{P_b}}{\sqrt{P_b} - \sqrt{P_c}} \cdot \frac{\sqrt{P_c}}{\sqrt{P_c} - \sqrt{P_a}}$$

区间越窄，倍数越大，资金利用率越高，但无常损失也按同样比例放大。

---

## 八、总结：公式体系全貌

```
起点：x · y = k（V2 恒定乘积）
  ↓ 限定价格区间 [Pa, Pb]
引入虚拟储备偏移量
  ↓ 定义 L = √k
(x + L/√Pb)(y + L√Pa) = L²   ← V3 核心公式
  ↓ 展开
x_real = L(1/√P - 1/√Pb)
y_real = L(√P - √Pa)
  ↓ 对 swap 求增量
Δy = L · Δ(√P)               ← swap 公式
Δx = L · Δ(1/√P)
  ↓ 离散化
P(i) = 1.0001^i               ← Tick 系统
sqrtPriceX96 = √P × 2^96     ← 定点数存储
```

---

> **核心洞察：** V3 的一切公式都来自于「在 $[P_a, P_b]$ 区间内满足恒定乘积」这一个约束条件，加上「边界处单一资产」这两个边界条件，通过代数推导自然得出。
