# 智能合约测试案例详解 - 真实Bug示例

> 通过真实案例说明：不写测试会出什么问题  
> 每个案例包含：有bug的代码 + 如果不测试会发生什么 + 正确的测试用例

---

## 目录

1. [部署测试案例](#1-部署测试案例)
2. [功能测试案例](#2-功能测试案例)
3. [边界测试案例](#3-边界测试案例)
4. [错误测试案例](#4-错误测试案例)
5. [事件测试案例](#5-事件测试案例)
6. [权限测试案例](#6-权限测试案例)
7. [状态测试案例](#7-状态测试案例)
8. [真实安全事件案例](#8-真实安全事件案例)

---

## 1. 部署测试案例

### 案例1.1：初始状态错误

#### 有Bug的合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _initialSupply;
        // ❌ Bug: 忘记给deployer分配初始供应量！
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 部署后
Token token = new Token("MyToken", "MTK", 1000000);

// 灾难性后果：
totalSupply = 1000000  ✅ 显示有100万代币
deployer.balanceOf = 0 ❌ 但owner的余额是0！
// 所有代币都丢失了！无法找回！
```

**真实后果**：代币永久丢失，无法转账，项目失败！

#### ✅ 正确的测试用例

```solidity
contract TokenTest is Test {
    Token public token;
    address public deployer;
    
    function setUp() public {
        deployer = address(this);
        token = new Token("MyToken", "MTK", 1000000);
    }
    
    // 部署测试1：初始供应量正确
    function test_Deployment_InitialSupply() public {
        assertEq(token.totalSupply(), 1000000);
    }
    
    // 部署测试2：deployer应该拥有所有代币
    function test_Deployment_DeployerBalance() public {
        // 这个测试会失败，暴露bug！
        assertEq(token.balanceOf(deployer), 1000000);
        // Expected: 1000000
        // Actual: 0
        // ❌ 测试失败！发现bug！
    }
}
```

#### 🔧 修复后的合约

```solidity
constructor(string memory _name, string memory _symbol, uint256 _initialSupply) {
    name = _name;
    symbol = _symbol;
    totalSupply = _initialSupply;
    balanceOf[msg.sender] = _initialSupply;  // ✅ 修复：给deployer分配代币
}
```

---

### 案例1.2：构造函数参数验证缺失

#### 有Bug的合约

```solidity
contract Vault {
    uint256 public lockDuration;
    
    constructor(uint256 _lockDuration) {
        lockDuration = _lockDuration;  // ❌ Bug: 没有验证参数
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 恶意或错误部署
Vault vault = new Vault(0);  // lockDuration = 0，锁定无效！
```

#### ✅ 正确的测试用例

```solidity
function test_RevertWhen_LockDurationIsZero() public {
    vm.expectRevert("Lock duration must be positive");
    new Vault(0);  // 应该失败但没有失败 → 发现bug
}
```

---

## 2. 功能测试案例

### 案例2.1：状态更新不一致

#### 有Bug的合约

```solidity
contract Staking {
    mapping(address => uint256) public stakedAmount;
    uint256 public totalStaked;
    
    function stake(uint256 amount) external {
        stakedAmount[msg.sender] += amount;
        // ❌ Bug: 忘记更新totalStaked！
        
        // 转入代币
        token.transferFrom(msg.sender, address(this), amount);
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 用户1质押100
staking.stake(100);
// 结果：
stakedAmount[user1] = 100  ✅
totalStaked = 0            ❌ 统计错误！

// 奖励计算基于totalStaked，所有用户都得不到奖励！
// 数据不一致，可能导致资金卡死！
```

#### ✅ 正确的测试用例

```solidity
function test_Stake_UpdatesTotalStaked() public {
    uint256 amount = 100e18;
    
    vm.prank(user1);
    staking.stake(amount);
    
    // 验证个人余额
    assertEq(staking.stakedAmount(user1), amount);
    
    // 验证总量（这个测试会失败，暴露bug！）
    assertEq(staking.totalStaked(), amount);
    // Expected: 100e18
    // Actual: 0
    // ❌ 测试失败！发现状态不一致！
}
```

---

## 3. 边界测试案例

### 案例3.1：零值转账漏洞

#### 有Bug的合约

```solidity
contract Token {
    mapping(address => uint256) public balanceOf;
    
    function transfer(address to, uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(msg.sender, to, amount);
        // ❌ Bug: 没有检查amount > 0
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 攻击者可以无限触发Transfer事件
for (uint i = 0; i < 1000000; i++) {
    token.transfer(victim, 0);  // 转账0个代币
}

// 后果：
// 1. Gas浪费攻击
// 2. 事件监听器被垃圾数据淹没
// 3. 区块浏览器显示异常
// 4. 前端/后端系统崩溃（处理百万无效事件）
```

**真实案例**：某些代币被用来进行垃圾交易攻击，导致区块浏览器无法正常显示。

#### ✅ 正确的测试用例

```solidity
// 边界测试：零值转账
function test_Transfer_WithZeroAmount() public {
    uint256 initialBalance = token.balanceOf(user1);
    
    vm.prank(user1);
    token.transfer(user2, 0);
    
    // 验证余额没变
    assertEq(token.balanceOf(user1), initialBalance);
    assertEq(token.balanceOf(user2), 0);
    
    // ❓ 但是emit了事件！这合理吗？
    // 这个测试让你思考：应该允许0转账吗？
}

// 更好的做法：不允许0转账
function test_RevertWhen_TransferZeroAmount() public {
    vm.expectRevert("Amount must be positive");
    vm.prank(user1);
    token.transfer(user2, 0);
}
```

---

### 案例3.2：整数溢出（Solidity 0.7及以下）

#### 有Bug的合约（Solidity 0.7）

```solidity
// Solidity 0.7.x - 没有自动溢出检查
contract UnsafeCounter {
    uint8 public count;  // 0-255
    
    function increment() external {
        count++;  // ❌ Bug: 255 + 1 = 0 (溢出)
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 初始 count = 255
counter.increment();
// 预期：count = 256 → 错误（uint8最大255）
// 实际：count = 0 （溢出回绕）

// 真实灾难：
// 1. 如果count是nonce，可能导致重放攻击
// 2. 如果count是余额，财产归零！
// 3. 如果count是权限级别，降级到最低权限！
```

**真实案例**：2018年 BatchOverflow 漏洞，导致多个代币可以凭空增发。

#### ✅ 正确的测试用例

```solidity
// 边界测试：最大值溢出
function test_Increment_AtMaxValue() public {
    // 设置到最大值
    counter.setCount(type(uint8).max);  // 255
    
    // 尝试增加
    counter.increment();
    
    // Solidity 0.8+: 应该revert
    // Solidity 0.7-: 会变成0（bug）
    
    // 这个测试在0.7会失败：
    assertEq(counter.count(), type(uint8).max);
    // Expected: 255
    // Actual: 0
    // ❌ 发现溢出bug！
}
```

---

### 案例3.3：数组越界

#### 有Bug的合约

```solidity
contract Lottery {
    address[] public participants;
    
    function getWinner(uint256 index) external view returns (address) {
        return participants[index];  // ❌ Bug: 没有边界检查
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// participants = [user1, user2]（2个人）
lottery.getWinner(5);  // 访问索引5

// 结果：Panic(0x32) - 数组越界
// 合约函数调用失败，用户体验差
```

#### ✅ 正确的测试用例

```solidity
function test_RevertWhen_GetWinner_IndexOutOfBounds() public {
    // 只有2个参与者
    lottery.addParticipant(user1);
    lottery.addParticipant(user2);
    
    // 尝试访问索引5
    vm.expectRevert();  // 应该捕获Panic(0x32)
    lottery.getWinner(5);
}

function test_GetWinner_EmptyArray() public {
    // 空数组
    vm.expectRevert();
    lottery.getWinner(0);  // 即使索引0也会失败
}
```

---

### 案例3.4：零地址漏洞

#### 有Bug的合约

```solidity
contract Token {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    
    function transfer(address to, uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        // ❌ Bug: 没有检查 to != address(0)
        
        emit Transfer(msg.sender, to, amount);
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 用户误操作或攻击
token.transfer(address(0), 1000);

// 后果：
// 1. 代币转到零地址，永久丢失（零地址私钥不存在）
// 2. totalSupply仍然显示包含这些代币
// 3. 实际流通量减少，数据不一致
// 4. 如果是销毁，应该减少totalSupply，但现在没有

// 真实案例：大量ERC20代币的零地址余额很高，都是被误转的
```

#### ✅ 正确的测试用例

```solidity
// 边界测试：零地址
function test_RevertWhen_TransferToZeroAddress() public {
    uint256 amount = 100;
    
    vm.expectRevert("Cannot transfer to zero address");
    vm.prank(user1);
    token.transfer(address(0), amount);
    // 这个测试会通过（发现没有检查零地址）→ bug暴露！
}
```

---

## 4. 错误测试案例

### 案例4.1：余额不足检查缺失

#### 有Bug的合约

```solidity
contract Vault {
    mapping(address => uint256) public deposits;
    
    function withdraw(uint256 amount) external {
        // ❌ Bug: 没有检查余额是否充足
        deposits[msg.sender] -= amount;
        
        payable(msg.sender).transfer(amount);
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 用户存款100
vault.deposit{value: 100}();
deposits[user] = 100

// 攻击者尝试提取1000
vault.withdraw(1000);

// Solidity 0.8+: 
// deposits[user] = 100 - 1000 会下溢
// → Panic(0x11) - 算术错误
// → 交易revert（幸运）

// Solidity 0.7-:
// 下溢回绕: 100 - 1000 = 很大的数
// deposits[user] = 115792...（uint256最大值-899）
// 但是transfer(1000)会失败（vault余额不足）
// → 状态不一致！用户账面余额巨大，但无法提取

// 更糟的情况：
// 如果是token.transfer而不是ETH
// 可能token余额够，攻击者就成功盗取了！
```

#### ✅ 正确的测试用例

```solidity
// 错误测试：余额不足
function test_RevertWhen_WithdrawInsufficientBalance() public {
    uint256 depositAmount = 100 ether;
    uint256 withdrawAmount = 200 ether;
    
    // 存入100
    vm.deal(user1, depositAmount);
    vm.prank(user1);
    vault.deposit{value: depositAmount}();
    
    // 尝试提取200
    vm.expectRevert("Insufficient balance");
    vm.prank(user1);
    vault.withdraw(withdrawAmount);
    
    // 如果没有require检查，这个测试会失败
    // 暴露bug！
}
```

---

### 案例4.2：重入攻击

#### 有Bug的合约

```solidity
contract Vault {
    mapping(address => uint256) public balances;
    
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        
        // ❌ Bug: 先转账，后更新状态（重入漏洞）
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        balances[msg.sender] = 0;  // 太晚了！
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 攻击合约
contract Attacker {
    Vault public vault;
    
    receive() external payable {
        // 收到钱时再次调用withdraw
        if (address(vault).balance > 0) {
            vault.withdraw();  // 重入攻击！
        }
    }
    
    function attack() external {
        vault.deposit{value: 1 ether}();
        vault.withdraw();
        // 1. withdraw()被调用
        // 2. 转账给Attacker
        // 3. Attacker.receive()被触发
        // 4. 再次调用withdraw()（此时balance还是1）
        // 5. 再次转账
        // 6. 无限循环，直到Vault被掏空！
    }
}

// 结果：Vault的所有资金被盗！
// 真实案例：2016年DAO攻击，损失6000万美元，导致以太坊硬分叉
```

#### ✅ 正确的测试用例

```solidity
// 错误测试：重入攻击
function test_ReentrancyAttack() public {
    // 准备：多个用户存款
    vm.deal(user1, 5 ether);
    vm.prank(user1);
    vault.deposit{value: 5 ether}();
    
    vm.deal(user2, 5 ether);
    vm.prank(user2);
    vault.deposit{value: 5 ether}();
    
    // 总余额: 10 ether
    
    // 攻击者存入1 ether
    Attacker attacker = new Attacker(address(vault));
    vm.deal(address(attacker), 1 ether);
    attacker.deposit{value: 1 ether}();
    
    // 记录攻击前的余额
    uint256 vaultBalanceBefore = address(vault).balance;  // 11 ether
    uint256 attackerBalanceBefore = address(attacker).balance;  // 0
    
    // 执行攻击
    attacker.attack();
    
    // 验证：攻击者不应该能提取超过1 ether
    uint256 attackerGain = address(attacker).balance - attackerBalanceBefore;
    
    // 如果有重入漏洞，这个测试会失败：
    assertLe(attackerGain, 1 ether, "Reentrancy attack successful!");
    // Expected: <= 1 ether
    // Actual: 11 ether (攻击者偷走了所有钱)
    // ❌ 测试失败！发现重入漏洞！
}
```

#### 🔧 修复方案

```solidity
function withdraw() external {
    uint256 amount = balances[msg.sender];
    require(amount > 0, "No balance");
    
    // ✅ 修复1：先更新状态，再转账（Checks-Effects-Interactions模式）
    balances[msg.sender] = 0;
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Transfer failed");
}

// 或者使用ReentrancyGuard
```

---

## 5. 事件测试案例

### 案例5.1：事件参数错误

#### 有Bug的合约

```solidity
contract Token {
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    function transfer(address to, uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        
        // ❌ Bug: 事件参数顺序错了
        emit Transfer(to, msg.sender, amount);  // from和to反了！
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 用户A转给用户B
tokenA.transfer(userB, 100);

// 区块浏览器显示：
// userB → userA: 100  ❌ 错了！实际是 A → B

// 后果：
// 1. 区块浏览器显示反向
// 2. 前端监听事件时，显示错误的发送者/接收者
// 3. 后端服务同步数据错误
// 4. 用户投诉："我明明收到钱了，为什么显示我发出去了？"
// 5. 交易所可能充值/提现记录混乱
```

#### ✅ 正确的测试用例

```solidity
// 事件测试
function test_Transfer_EmitsCorrectEvent() public {
    uint256 amount = 100;
    
    // 预期事件
    vm.expectEmit(true, true, false, true);
    emit Transfer(user1, user2, amount);  // 正确的顺序
    
    // 执行转账
    vm.prank(user1);
    token.transfer(user2, amount);
    
    // 如果事件参数错误，这个测试会失败：
    // Expected: Transfer(user1, user2, 100)
    // Actual: Transfer(user2, user1, 100)
    // ❌ 测试失败！发现事件参数错误！
}
```

---

### 案例5.2：缺少事件触发

#### 有Bug的合约

```solidity
contract Ownable {
    address public owner;
    
    function transferOwnership(address newOwner) external {
        require(msg.sender == owner, "Not owner");
        owner = newOwner;
        // ❌ Bug: 忘记emit事件
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 转移所有权
ownable.transferOwnership(newOwner);

// 后果：
// 1. 区块浏览器无法追踪所有权变更历史
// 2. 审计困难：无法查询谁曾是owner
// 3. 前端/后端无法监听所有权变更事件
// 4. 安全监控系统无法告警
// 5. 如果发生纠纷，无法证明所有权变更时间
```

#### ✅ 正确的测试用例

```solidity
function test_TransferOwnership_EmitsEvent() public {
    address newOwner = address(0x123);
    
    // 预期触发事件
    vm.expectEmit(true, true, false, false);
    emit OwnershipTransferred(owner, newOwner);
    
    vm.prank(owner);
    ownable.transferOwnership(newOwner);
    
    // 如果没有emit，这个测试会失败
    // ❌ 发现缺少事件！
}
```

---

## 6. 权限测试案例

### 案例6.1：权限控制缺失

#### 有Bug的合约

```solidity
contract Token {
    address public owner;
    uint256 public totalSupply;
    
    function mint(address to, uint256 amount) external {
        // ❌ Bug: 任何人都可以铸造！
        balanceOf[to] += amount;
        totalSupply += amount;
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 攻击者调用
attacker.call(token, "mint", attacker, 1000000000000);

// 结果：攻击者凭空创造无限代币！
// 代币价值归零，项目崩盘！

// 真实案例：
// - 2018年，多个ERC20代币存在此类漏洞
// - 攻击者铸造大量代币倾销，价格暴跌
// - 项目方甚至不知道为什么代币供应突然暴增
```

#### ✅ 正确的测试用例

```solidity
// 权限测试：非owner不能mint
function test_RevertWhen_NonOwnerCallsMint() public {
    address attacker = address(0x999);
    
    vm.expectRevert("Ownable: caller is not the owner");
    vm.prank(attacker);  // 模拟attacker调用
    token.mint(attacker, 1000000);
    
    // 如果没有权限检查，这个测试会通过（mint成功）
    // → 暴露权限漏洞！
}

// 权限测试：owner可以mint
function test_Owner_CanMint() public {
    uint256 amount = 1000;
    
    vm.prank(owner);
    token.mint(user1, amount);
    
    assertEq(token.balanceOf(user1), amount);
}
```

---

### 案例6.2：权限检查顺序错误

#### 有Bug的合约

```solidity
contract Vault {
    mapping(address => uint256) public deposits;
    
    function emergencyWithdraw() external {
        uint256 amount = deposits[msg.sender];
        
        // ❌ Bug: 先转账，后检查权限
        payable(msg.sender).transfer(amount);
        
        require(msg.sender == owner, "Only owner");
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 任何用户调用
user.call(vault, "emergencyWithdraw");

// 1. transfer执行成功（用户收到钱）
// 2. require检查失败
// 3. 整个交易revert
// 4. 但如果transfer是外部调用，可能已经有副作用

// 更糟的情况（如果是token.transfer）：
// 可能token转账成功，但最后revert
// 导致状态不一致
```

#### ✅ 正确的测试用例

```solidity
function test_RevertWhen_NonOwnerCallsEmergencyWithdraw() public {
    vm.deal(user1, 10 ether);
    vm.prank(user1);
    vault.deposit{value: 10 ether}();
    
    uint256 balanceBefore = address(user1).balance;
    
    vm.expectRevert("Only owner");
    vm.prank(user1);
    vault.emergencyWithdraw();
    
    // 验证余额没有变化
    assertEq(address(user1).balance, balanceBefore);
}
```

---

## 7. 状态测试案例

### 案例7.1：状态转换错误

#### 有Bug的合约

```solidity
contract Crowdsale {
    enum State { Pending, Active, Ended, Cancelled }
    State public state;
    
    function start() external {
        require(msg.sender == owner, "Not owner");
        state = State.Active;
    }
    
    function end() external {
        require(msg.sender == owner, "Not owner");
        state = State.Ended;
        // ❌ Bug: 没有检查当前状态，可以从任何状态转到Ended
    }
}
```

#### 💥 如果不测试会发生什么？

```solidity
// 正常流程：Pending → Active → Ended
crowdsale.start();  // Pending → Active ✅
crowdsale.end();    // Active → Ended ✅

// 异常流程：
Crowdsale bad = new Crowdsale();
bad.end();  // Pending → Ended ❌ 没有经过Active就结束了！

// 或者：
crowdsale.cancel();  // Cancelled
crowdsale.end();     // Cancelled → Ended ❌ 取消后还能结束？

// 后果：
// 1. 业务逻辑混乱
// 2. 资金分配错误
// 3. 退款流程失效
```

#### ✅ 正确的测试用例

```solidity
// 状态测试：不能从Pending直接到Ended
function test_RevertWhen_EndWithoutStart() public {
    // 初始状态是Pending
    assertEq(uint(crowdsale.state()), uint(State.Pending));
    
    vm.expectRevert("Must be active");
    vm.prank(owner);
    crowdsale.end();
    
    // 如果没有状态检查，测试会失败
    // → 发现状态转换漏洞！
}

// 状态测试：不能从Cancelled到Ended
function test_RevertWhen_EndAfterCancel() public {
    vm.prank(owner);
    crowdsale.start();
    
    vm.prank(owner);
    crowdsale.cancel();
    
    assertEq(uint(crowdsale.state()), uint(State.Cancelled));
    
    vm.expectRevert("Cannot end cancelled sale");
    vm.prank(owner);
    crowdsale.end();
}

// 状态测试：正确的状态转换
function test_StateTransition_Correct() public {
    // Pending → Active
    vm.prank(owner);
    crowdsale.start();
    assertEq(uint(crowdsale.state()), uint(State.Active));
    
    // Active → Ended
    vm.prank(owner);
    crowdsale.end();
    assertEq(uint(crowdsale.state()), uint(State.Ended));
}
```

---

## 8. 真实安全事件案例

### 案例8.1：Parity 多签钱包自毁事件（2017）

#### 问题代码（简化版）

```solidity
contract WalletLibrary {
    address public owner;
    
    // ❌ Bug1: initWallet没有初始化检查
    function initWallet(address _owner) public {
        owner = _owner;
    }
    
    // ❌ Bug2: kill函数没有保护
    function kill() public {
        require(msg.sender == owner);
        selfdestruct(payable(owner));
    }
}

contract Wallet {
    address public library;
    
    constructor(address _library) {
        library = _library;
    }
    
    fallback() external {
        // 委托调用library
        library.delegatecall(msg.data);
    }
}
```

#### 💥 发生了什么？

```solidity
// 1. 攻击者调用library的initWallet
walletLibrary.initWallet(attacker);
// library.owner = attacker （library合约的owner被攻击者设置）

// 2. 攻击者调用kill
walletLibrary.kill();
// library合约自毁！

// 3. 所有依赖这个library的钱包全部失效
// 513,774 ETH 永久冻结（当时价值3亿美元）
```

#### ✅ 应该有的测试

```solidity
// 测试：library不应该能被初始化两次
function test_RevertWhen_InitWalletTwice() public {
    walletLibrary.initWallet(owner);
    
    vm.expectRevert("Already initialized");
    walletLibrary.initWallet(attacker);
}

// 测试：普通用户不能初始化library
function test_RevertWhen_NonOwnerInitializesLibrary() public {
    vm.expectRevert("Unauthorized");
    vm.prank(attacker);
    walletLibrary.initWallet(attacker);
}

// 测试：library不应该能被销毁
function test_LibraryCannotBeSelfDestructed() public {
    vm.expectRevert("Library cannot be destroyed");
    vm.prank(owner);
    walletLibrary.kill();
}
```

---

### 案例8.2：整数溢出 - BEC代币事件（2018）

#### 问题代码

```solidity
// Solidity 0.4.x - 没有自动溢出检查
contract BECToken {
    mapping(address => uint256) public balanceOf;
    
    // ❌ Bug: 批量转账时amount * cnt可能溢出
    function batchTransfer(address[] _receivers, uint256 _value) public {
        uint cnt = _receivers.length;
        uint256 amount = uint256(cnt) * _value;
        
        require(cnt > 0 && cnt <= 20);
        require(_value > 0 && balanceOf[msg.sender] >= amount);
        
        balanceOf[msg.sender] -= amount;
        for (uint i = 0; i < cnt; i++) {
            balanceOf[_receivers[i]] += _value;
        }
    }
}
```

#### 💥 发生了什么？

```solidity
// 攻击参数：
// _receivers = [addr1, addr2]  (cnt = 2)
// _value = 2^255 (非常大的数)

// 计算：
uint256 amount = 2 * (2^255)
// 溢出：2 * 2^255 = 2^256 = 0 (uint256溢出回绕)

// require检查：
require(balanceOf[msg.sender] >= 0);  // ✅ 通过（0 <= 任何余额）

// 结果：
balanceOf[msg.sender] -= 0;  // 发送者余额不变
balanceOf[addr1] += 2^255;    // 接收者1获得天量代币
balanceOf[addr2] += 2^255;    // 接收者2获得天量代币

// 攻击者凭空创造了 2^256 个代币！
// BEC代币暴跌，市值蒸发
```

#### ✅ 应该有的测试

```solidity
// 边界测试：大数值乘法溢出
function test_RevertWhen_BatchTransferOverflow() public {
    address[] memory receivers = new address[](2);
    receivers[0] = user1;
    receivers[1] = user2;
    
    // 设计溢出：2 * (2^255) = 0
    uint256 value = 2**255;
    
    vm.expectRevert();  // 应该revert，但0.4.x不会
    vm.prank(attacker);
    token.batchTransfer(receivers, value);
    
    // Solidity 0.4.x: 这个测试会失败（没有revert）
    // → 发现溢出漏洞！
}

// 边界测试：最大值溢出
function test_Multiplication_DoesNotOverflow() public {
    uint256 cnt = 2;
    uint256 value = type(uint256).max / 2 + 1;
    
    // cnt * value 会溢出
    uint256 amount;
    unchecked {
        amount = cnt * value;
    }
    
    // 验证是否检测到溢出
    assertTrue(amount < value, "Overflow not detected");
    
    // 正确的做法：使用SafeMath或Solidity 0.8+
}
```

---

### 案例8.3：Compound 清算漏洞（2020）

#### 问题代码（简化版）

```solidity
contract Comptroller {
    // ❌ Bug: 清算计算公式错误
    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint repayAmount
    ) external returns (uint) {
        // 计算可清算数量
        uint maxClose = mul_ScalarTruncate(
            Exp({mantissa: closeFactorMantissa}),
            borrowBalance
        );
        
        // ❌ Bug: 没有检查 repayAmount <= maxClose
        // 允许清算超过允许的数量
        
        return uint(Error.NO_ERROR);
    }
}
```

#### 💥 发生了什么？

```solidity
// 正常情况：只能清算50%的债务
// 清算者应该只能清算 50% * 100 = 50 DAI

// 但由于bug：
liquidator.liquidateBorrow(borrower, 80);  // 清算80 DAI
// 本应失败，但成功了！

// 后果：
// 1. 清算者可以清算超额债务
// 2. 获得更多抵押品奖励
// 3. 借款人损失过多抵押品
// 4. 协议损失约8000万美元
```

#### ✅ 应该有的测试

```solidity
// 边界测试：不能过度清算
function test_RevertWhen_LiquidateMoreThanAllowed() public {
    // 设置：用户借了100 DAI，清算因子50%
    uint256 borrowAmount = 100e18;
    uint256 closeFactor = 0.5e18;  // 50%
    uint256 maxLiquidation = borrowAmount * closeFactor / 1e18;  // 50 DAI
    
    // 尝试清算80 DAI（超过50%）
    uint256 repayAmount = 80e18;
    
    vm.expectRevert("Liquidate too much");
    comptroller.liquidateBorrow(
        cTokenBorrowed,
        cTokenCollateral,
        borrower,
        repayAmount
    );
    
    // 如果没有检查，这个测试会失败
    // → 发现过度清算漏洞！
}

// 边界测试：恰好允许的清算量
function test_Liquidate_ExactlyMaxAmount() public {
    uint256 borrowAmount = 100e18;
    uint256 maxLiquidation = 50e18;
    
    // 清算恰好50 DAI
    comptroller.liquidateBorrow(
        cTokenBorrowed,
        cTokenCollateral,
        borrower,
        maxLiquidation
    );
    
    // 应该成功
}
```

---

## 9. 总结：测试的价值

### 各类测试发现的典型Bug

| 测试类型 | 典型Bug | 真实案例 |
|---------|---------|---------|
| **部署测试** | 初始状态错误、参数验证缺失 | 代币初始供应丢失 |
| **功能测试** | 状态更新不一致、逻辑错误 | Staking奖励计算错误 |
| **边界测试** | 溢出、零值、最大值、零地址 | BEC溢出、DAO攻击 |
| **错误测试** | 余额检查、重入、权限 | Parity冻结3亿美元 |
| **事件测试** | 事件缺失、参数错误 | 审计追踪失败 |
| **权限测试** | 权限控制缺失、检查顺序 | 无限铸币漏洞 |
| **状态测试** | 状态转换错误、不变量破坏 | 众筹状态混乱 |

### 测试成本 vs 漏洞成本

```
编写测试成本：
- 时间：几小时到几天
- 费用：开发人员工资

不测试的成本：
- Parity事件：3亿美元冻结
- BEC溢出：市值归零
- Compound漏洞：8000万美元
- DAO攻击：6000万美元 + 以太坊硬分叉

ROI = ∞（无限大）
```

### 测试检查清单

每个合约都应该测试：

```
□ 部署后初始状态正确
□ 所有public/external函数的正常流程
□ 零值、最大值、零地址等边界条件
□ 所有require和revert路径
□ 所有事件触发和参数
□ 所有权限控制
□ 状态转换的合法性
□ 可能的重入攻击
□ 整数溢出/下溢
□ 外部调用的安全性
```

---

## 10. 实践建议

### 开发流程

```
1. 编写合约代码
   ↓
2. 编写测试（参考本文档的案例）
   ↓
3. 运行测试
   ↓
4. 发现bug → 修复 → 重新测试
   ↓
5. 代码审计
   ↓
6. 部署到测试网
   ↓
7. 部署到主网
```

### 测试优先级

**必须测试（P0）**：
- 涉及资金的所有函数
- 权限控制
- 状态转换
- 边界条件

**应该测试（P1）**：
- 事件触发
- 查询函数
- 辅助函数

**可选测试（P2）**：
- 性能测试
- Gas优化测试

---

**记住：每个没写的测试，都可能是一个未来的漏洞！** 🛡️

**测试不是负担，是保护你的代码和用户资金的第一道防线！** 💪
