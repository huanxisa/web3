# 资产清单（Inventory）

> 所有路径以 workspace root `/Users/piliepeng/cursor/go/` 为基准。
> 你（agent）**不要花时间重新探索目录结构**，直接照这个清单找文件。

---

## 一、已克隆的开源仓库（7 个核心 + 配套）

按 8 周顺序排列：

| 周 | 项目 | 仓库目录 | 核心文件（业务速读） |
|---|---|---|---|
| **W1** | Uniswap V3 | `web3-job-hunting/repos/dex/uniswap-v3-core/` | `contracts/UniswapV3Pool.sol` `contracts/UniswapV3Factory.sol` |
| W1 | Uniswap V3 Subgraph | `web3-job-hunting/repos/dex/uniswap-v3-subgraph/` | `subgraphs/v3/src/mappings/` |
| **W2** | Aave V3 | `web3-job-hunting/repos/lending/aave-v3-core/` | `contracts/protocol/pool/Pool.sol` |
| W2 | Aave Subgraphs | `web3-job-hunting/repos/lending/aave-protocol-subgraphs/` | `subgraphs/protocol-v3/src/mapping/` |
| W2 | Aave Utilities | `web3-job-hunting/repos/lending/aave-utilities/` | `packages/math-utils/src/formatters/user/` |
| **W3** | MakerDAO DSS | `web3-job-hunting/repos/stablecoin/makerdao-dss/` | `src/vat.sol` `src/jug.sol` `src/cat.sol` |
| W3 | Maker CDP Manager | `web3-job-hunting/repos/stablecoin/makerdao-cdp-manager/` | `src/DssCdpManager.sol` |
| W3 | Maker Auction Keeper | `web3-job-hunting/repos/stablecoin/makerdao-auction-keeper/` | `auction_keeper/main.py` |
| **W4** | Lido DAO | `web3-job-hunting/repos/stablecoin/lido-dao/` | `contracts/0.4.24/Lido.sol` |
| W4 | Lido Oracle | `web3-job-hunting/repos/stablecoin/lido-oracle/` | `src/services/` |
| W4 | Lido Subgraph | `web3-job-hunting/repos/stablecoin/lido-subgraph/` | `src/mapping.ts` |
| **W5** | dYdX V4 | `web3-job-hunting/repos/trading-engine/dydx-v4-chain/` | `protocol/x/clob/keeper/` `indexer/services/` |
| W5 | LMAX Disruptor（参考） | `web3-job-hunting/repos/trading-engine/lmax-disruptor/` | 撮合引擎 ringbuffer 设计参考 |
| **W6** | Binance tss-lib | `web3-job-hunting/repos/mpc-wallet/binance-tss-lib/` | `ecdsa/keygen/` `ecdsa/signing/` |
| **W7** | Safe Smart Account | `web3-job-hunting/repos/innovation/safe-smart-account/` | `contracts/Safe.sol` |
| W7 | Safe Modules | `web3-job-hunting/repos/innovation/safe-modules/` | `modules/allowances/contracts/` |
| W7 | Safe Tx Service | `web3-job-hunting/repos/innovation/safe-transaction-service/` | `safe_transaction_service/history/` |
| W7 | safe-eth-py | `web3-job-hunting/repos/innovation/safe-eth-py/` | `gnosis/safe/` |
| **W8.①** | EigenLayer 合约 | `web3-job-hunting/repos/innovation/eigenlayer-contracts/` | `src/contracts/core/` |
| W8.① | EigenSDK Go | `web3-job-hunting/repos/innovation/eigensdk-go/` | `chainio/clients/` |
| W8.① | EigenDA | `web3-job-hunting/repos/innovation/eigenda/` | `core/` |
| **W8.②** | LayerZero V2 | `web3-job-hunting/repos/bridge/layerzero-v2/` | `packages/layerzero-v2/evm/protocol/` |
| **W8.③** | Pendle V2 | `web3-job-hunting/repos/derivatives/pendle-core-v2/` | `contracts/core/` |

---

## 二、文档资产（按用途分类）

### 学习地图（按时间从新到旧，**只看 v4**）

| 文档 | 状态 | 说明 |
|---|---|---|
| [`../../reports/learning_roadmap_v4_backend_first.md`](../../reports/learning_roadmap_v4_backend_first.md) | ⭐ **当前生效** | 后端先行版，已锁定 |
| `../../reports/learning_roadmap_v3_universal.md` | 🟡 已废弃 | v3 通用路径，被 v4 替代 |
| `../../reports/business_focused_repos_for_newcomers.md` | 📦 v1 留存 | 合约视角项目清单（合约篇用） |
| `../../reports/business_focused_repos_v2_data_driven.md` | 📦 v2 留存 | GAP 分析（CEX/MPC/桥/Indexer 5 大缺口） |

### 求职情报

| 文档 | 用途 |
|---|---|
| `../../reports/jd_summary.md` | 884 个命中岗位的 JD 汇总（数据来源）|
| `../../reports/final_repo_shortlist.md` | 已 clone 仓库的最终短名单 |
| `../../reports/biz_to_opensource_map.md` | 业务-开源仓库映射表 |
| `../../reports/dead_companies_dm_sop.md` | 用 Twitter/LinkedIn DM 联系冷门公司的 SOP |
| `../../reports/diff_*.md` | 各次抓取增量报告 |

### 个人学习笔记（你产出的去处）

| 目录 | 用途 |
|---|---|
| [`../weekly/backend/`](../weekly/backend/) | 8 周后端篇笔记（W1-W8 已占位） |
| `../weekly/contract/` | 合约篇笔记（W8 之后再开） |
| `../_template/` | 4 套模板（business_card / system_design / demo_readme / weekly_qa） |
| `../demos/` | 3 个核心 Demo 的复盘（W2/W5/W6 完成后写） |
| [`../resume/`](../resume/) | 简历构建（template + stories + one_liners） |

---

## 三、数据库（求职数据）

### jobs.db（SQLite）

- 路径：`web3-job-hunting/data/jobs.db`
- 当前数据：884 个命中岗位 + Feishu 1462 行 + Telegram + GitHub issues
- 表：`jobs`, `companies`, `sources`
- **agent 不需要查 DB**，所有需要的信息都在 `reports/jd_summary.md` 里渲染好了
- 关键字段：`description`（原始）/ `description_text`（清洗）/ `description_zh`（中文翻译）/ `title_zh`（中文标题）

### 🟢 中文 JD 保障（用户硬要求）

> 用户原话："**没有提供给我完整的中文的 jd，请修正这一点，后续的更新都需要这一点**"

每次更新流程必须保证 `reports/jd_summary.md` 里每个岗位都附**可展开的完整中文 JD**：

| 数据源 | 中文 JD 来源 | 已确保 |
|---|---|---|
| ATS（英文） | `translator.py` 用 GoogleTranslator 翻译到 `description_zh` | ✅ 已修 |
| 飞书内推 | 本身中文，存在 `description_text` | ✅ 已修（修正了之前用错的 `description` 字段 bug）|
| Telegram | 频道帖含中文/英文混排，翻译写入 `description_zh` | ✅ 已修 |
| web3.career | 英文为主，翻译写入 `description_zh` | ✅ 已修 |
| GitHub issues | 本身中文，存在 `description_text` | ✅ 已修 |

每条岗位卡片末尾必有 `<details><summary>📄 JD 全文（标签）</summary>` 折叠块，标签为：
- "中文翻译"（来自 `description_zh`）
- "原文（中文）"（本身就是中文）
- "⚠️ 英文原文（未翻译 — 运行 `python scripts/translator.py` 可补中文）"（fallback）

**更新流程**（任何 agent 修改后必须验证）：

```bash
.venv/bin/python -u scripts/update.py   # 抓取 + 翻译 + 生成报告（一键）
# 或者只跑翻译 + 重生成：
.venv/bin/python -u scripts/translator.py
.venv/bin/python scripts/reporter.py
```

> ⚠️ Python 在 sandbox 内调 Google Translate API 会被网络限制阻挡，需 `required_permissions: ["all"]` 跑（agent 用 Shell 时记得加）。

---

## 四、采集脚本（已稳定运行，不要乱碰）

| 脚本 | 作用 | 状态 |
|---|---|---|
| `web3-job-hunting/scripts/update.py` | 一键增量更新所有数据源 | ✅ 稳定 |
| `web3-job-hunting/scripts/reporter.py` | 生成 jd_summary.md | ✅ 稳定 |
| `web3-job-hunting/scripts/feishu_extract.py` | 飞书内推池抓取（playwright） | ✅ 稳定 |
| `web3-job-hunting/scripts/telegram_fetcher.py` | Telegram 频道抓取 | ✅ 稳定 |
| `web3-job-hunting/scripts/web3career_search.py` | web3.career 关键词搜 | ✅ 稳定 |
| `web3-job-hunting/scripts/github_hiring.py` | GitHub who-is-hiring 抓取 | ✅ 稳定 |
| `web3-job-hunting/scripts/clone_repos.sh` | 一键克隆所有仓库 | ✅ 稳定 |

→ **agent 不要改这些脚本**，除非用户明确要求"加新数据源"或"修 bug"。

---

## 五、Demo 工作区（PoC 落地处）

| 路径 | 用途 |
|---|---|
| `web3-job-hunting/repos/_demos/W{N}_{1,2}_{name}/` | 每周 PoC 放这里（约定路径） |
| 例：`repos/_demos/W2_1_aave_health_monitor/` | W2 系统设计 #1 的 PoC |
| 例：`repos/_demos/W5_1_erc20_indexer/` | W5 系统设计 #1 的 PoC |

> 当 PoC 成熟（达到推 GitHub 标准）后，可单独 `git init` 建独立 repo。

---

## 六、外部资源（agent 找文档时优先用）

| 协议 | 官方业务文档 |
|---|---|
| Uniswap V3 | <https://docs.uniswap.org/concepts/protocol/concentrated-liquidity> |
| Aave V3 | <https://docs.aave.com/developers/core-contracts/pool> |
| MakerDAO | <https://docs.makerdao.com/smart-contract-modules/core-module> |
| Lido | <https://docs.lido.fi/contracts/lido> |
| dYdX V4 | <https://docs.dydx.exchange/concepts-architecture> |
| Binance tss-lib | <https://github.com/bnb-chain/tss-lib/blob/master/README.md> |
| Safe | <https://docs.safe.global/advanced/smart-account-overview> |
| EigenLayer | <https://docs.eigenlayer.xyz/eigenlayer/overview> |
| LayerZero | <https://docs.layerzero.network/v2/concepts/overview> |
| Pendle | <https://docs.pendle.finance/ProtocolMechanics/Overview> |

---

## 七、什么情况下查 inventory.md

| 用户问 / 你想 | 找哪一节 |
|---|---|
| "Aave 的 Pool 合约在哪？" | 第 1 节，按 W2 行查 |
| "v3 那份地图是哪份？" | 第 2 节"学习地图" |
| "已经有多少岗位数据？" | 第 3 节 jobs.db |
| "Demo 应该放哪？" | 第 5 节 |
| "Lido 官方文档地址？" | 第 6 节 |
