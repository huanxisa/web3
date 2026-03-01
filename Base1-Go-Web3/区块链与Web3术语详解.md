区块链与Web3术语详解（A-Z）

A

Address（地址）  
区块链网络中用于标识资产接收与发送的唯一字符串，由公钥通过哈希算法生成。常见类型：  

- 比特币地址：Base58编码（如1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa）  

- 以太坊地址：十六进制0x开头（如0x742d35Cc6634C0532925a3b844Bc454e4438f44e）  

- 兼容性：支持跨链的地址格式（如Bech32用于BTC SegWit）



Altcoin（替代币）  
比特币以外的加密货币统称，按功能分类：  

- 支付型：Litecoin（LTC）、Bitcoin Cash（BCH）  

- 智能合约平台：Ethereum（ETH）、Solana（SOL）  

- 隐私型：Monero（XMR）、Zcash（ZEC）



AMM（自动化做市商）  
基于数学公式的流动性提供机制，核心模型：  

- 恒定乘积模型：Uniswap V2（x*y=k）  

- 集中流动性：Uniswap V3（允许自定义价格区间）  

- 稳定币互换：Curve Finance（低滑点交易）

B

Block（区块）  
区块链数据存储单元，包含：  

- 区块头：版本号、时间戳、Merkle根、难度目标、Nonce  

- 区块体：交易列表（比特币约4000笔/区块，以太坊约300笔）  

- 确认机制：比特币6确认视为最终确认（约1小时）



Blockchain（区块链）  
核心技术特征：  

- 分布式账本：全网节点同步数据副本  

- 共识算法：PoW、PoS、DPoS等（参见C章节）  

- 不可逆性：通过哈希链式结构实现（修改任一区块需重构后续所有区块）



Byzantine Fault Tolerance（拜占庭容错）  
分布式系统容错级别分类：  

- CFT（故障容错）：处理节点宕机问题（如Raft算法）  

- BFT（拜占庭容错）：应对恶意节点作恶（如PBFT、Tendermint）  

- 异步BFT：DiemBFT（Libra区块链采用）

C

Consensus Mechanism（共识机制）  
主流类型与技术参数：  

类型
代表项目
能耗
TPS
去中心化程度
PoW
比特币
极高
7
高
PoS
以太坊2.0
低
100k
中
DPoS
EOS
低
4000
低
PoH
Solana
中
65k
中



Cryptocurrency（加密货币）  
监管分类：  

- 支付型代币：比特币（日本认定为合法支付手段）  

- 证券型代币：部分ICO项目受SEC监管（如Telegram的TON）  

- 实用型代币：Filecoin（用于购买存储服务）

D

DAO（去中心化自治组织）  
治理模型演进：  

- 一代DAO：The DAO（2016年，因漏洞失败）  

- 二代DAO：MakerDAO（MKR持有者决定稳定费利率）  

- 模块化DAO：Aragon（提供DAO创建模板）



DeFi（去中心化金融）  
核心赛道与TVL（2025年数据）：  

1. 借贷：Aave（$12B）、Compound（$8B）  

2. DEX：Uniswap（$25B）、Curve（$7B）  

3. 衍生品：dYdX（$3B）、GMX（$2B）  

4. 保险：Nexus Mutual（$1B）

E

Ethereum（以太坊）  
关键升级路线：  

- The Merge（2022）：PoW转PoS  

- Surge（2023）：分片扩容至10万TPS  

- Verge（2024）：引入Verkle树优化存储  

- Purge（2025）：简化协议历史数据



ERC标准  
扩展协议：  

- ERC-1155：混合代币标准（支持同质化与非同质化代币共存）  

- ERC-4337：账户抽象（允许智能合约钱包）  

- ERC-721R：可退款NFT（防止项目方跑路）

F

Fork（分叉）  
著名分叉事件：  

- 比特币分叉：产生BCH（2017）、BSV（2018）  

- 以太坊分叉：ETC（2016 The DAO事件后分裂）  

- 治理分叉：SushiSwap（从Uniswap分叉并创新代币模型）

G

Gas（燃料费）  
以太坊费用机制：  

- Gas Limit：单笔交易最大计算量（基础值21,000）  

- Base Fee：根据EIP-1559动态调整（部分销毁）  

- Priority Fee：矿工/验证者小费

H

Hash（哈希）  
常用算法对比：  

算法
输出长度
应用场景
SHA-256
256bit
比特币挖矿
Keccak-256
256bit
以太坊智能合约
Blake2b
512bit
Cardano、Zcash

I

IPFS（星际文件系统）  
技术组件：  

- CID：内容标识符（基于哈希而非位置寻址）  

- Filecoin：激励层（存储矿工需质押FIL代币）  

- 应用案例：Arweave（永久存储）、Ceramic（动态数据协议）

L

Layer 2（二层扩容）  
主流方案对比：  

类型
代表项目
安全性来源
提款时间
Rollup
Optimism
以太坊主网
7天
zkRollup
zkSync
零知识证明
10分钟
Plasma
OMG Network
欺诈证明
1周
Validium
StarkEx
链下数据可用性
即时

M

Mining（挖矿）  
设备演进史：  

5. CPU挖矿（2009-2010）  

6. GPU挖矿（2010-2013）  

7. ASIC矿机（2013至今，比特大陆Antminer系列）  

8. 云挖矿（Hashnest等平台提供算力租赁）

N

NFT（非同质化代币）  
创新形态：  

- 动态NFT：Art Blocks（根据链上数据变化）  

- 物理绑定NFT：RTFKT（与实体球鞋绑定）  

- 金融化NFT：BendDAO（支持NFT抵押借贷）

O

Oracle（预言机）  
数据验证机制：  

- 单一来源：Chainlink（多节点聚合数据）  

- 去中心化预言机：Band Protocol（基于PoS共识）  

- 跨链预言机：Witnet（支持多链数据调用）

P

Private Key（私钥）  
安全管理方案：  

- 硬件钱包：Ledger、Trezor  

- 多重签名：Gnosis Safe（需多个私钥共同签署交易）  

- 社交恢复：Argent钱包（设置可信联系人）

S

Smart Contract（智能合约）  
开发语言：  

- Solidity：以太坊主流语言（类JavaScript语法）  

- Rust：Solana、Polkadot首选语言  

- Move：Aptos/Sui专用语言（资源导向型）

T

Tokenomics（代币经济学）  
设计要素：  

- 通胀模型：ETH无硬顶 vs 比特币2100万上限  

- 燃烧机制：BNB季度销毁、EIP-1559基础费销毁  

- 质押收益：Cosmos（约15%年化）、Cardano（约5%）

W

Web3  
技术栈分层：  

- 协议层：IPFS、Arweave（去中心化存储）  

- 中间件：The Graph（链上数据索引）  

- 应用层：Brave浏览器（整合IPFS、加密货币支付）

Z

Zero-Knowledge Proof（零知识证明）  
应用方向：  

- 隐私交易：Zcash（zk-SNARKs）  

- 扩容方案：zkSync、StarkNet（zkRollup）  

- 身份验证：Polygon ID（ZK凭证验证）



