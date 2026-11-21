# MongoDB 面试题

### 1. 存储引擎相关
**Q: 请详细解释 WiredTiger 存储引擎的工作原理及其与 MMAPv1 的主要区别？**

**A:**
- WiredTiger 特点：
  - 使用 B+ 树存储数据和索引
  - 实现了数据压缩（snappy 和 zlib）
  - 支持文档级别的并发控制
  - 实现检查点机制（checkpoint）确保数据持久性
  - 写操作使用 MVCC (多版本并发控制)

与 MMAPv1 的主要区别：
- 并发控制：WiredTiger 支持文档级别锁，MMAPv1 是集合级别锁
- 数据压缩：WiredTiger 支持压缩，MMAPv1 不支持
- 内存使用：WiredTiger 使用内部缓存，MMAPv1 依赖系统页缓存

### 2. 复制集机制
**Q: MongoDB 的复制集同步机制是如何工作的？oplog 在其中扮演什么角色？**

**A:**
- 初始同步过程：
  1. 克隆所有数据库
  2. 追赶应用 oplog
  3. 建立索引

- oplog 特性：
  - 固定集合（capped collection）
  - 幂等性操作
  - 基于时间戳
  - 存储格式为：`{ts: timestamp, op: operation_type, ns: namespace, o: operation_document}`

### 3. 分片架构
**Q: 在设计分片集群时，如何选择合适的片键？需要考虑哪些因素？**

**A:**
关键考虑因素：
1. 基数（Cardinality）：片键值的唯一性
2. 写分布：避免写热点
3. 定向查询效率
4. 数据分布均匀性
5. 分片大小

最佳实践：
- 使用复合片键
- 避免单调递增的片键
- 考虑业务访问模式

### 4. 性能调优
**Q: 如何诊断和优化 MongoDB 的慢查询？explain() 输出中的哪些指标最重要？**

**A:**
关键诊断步骤：
1. 使用 explain() 分析：
   - executionStats 模式查看具体执行计划
   - 关注 IXSCAN vs COLLSCAN
   - 检查 nReturned 和 totalKeysExamined 比例

2. 重要指标：
   - stage：执行阶段（FETCH、IXSCAN、SORT等）
   - nReturned：返回文档数
   - totalKeysExamined：扫描索引条目数
   - totalDocsExamined：扫描文档数
   - executionTimeMillis：执行时间

### 5. 数据同步相关
**Q: 在实现数据库同步工具时，如何保证数据一致性和高效性？**

**A:**
关键实现策略：
1. 初始同步：
   - 使用 snapshot 或一致性快照
   - 并行导出导入
   - 检查点机制

2. 增量同步：
   - 基于 oplog 追踪变更
   - 实现幂等性操作
   - 处理 oplog 回滚情况

3. 性能优化：
   - 批量操作
   - 并行处理
   - 错误重试机制

### 6. 事务机制
**Q: MongoDB 4.0+ 的事务实现原理是什么？在分布式环境下如何保证事务的 ACID 特性？**

**A:**
实现原理：
1. 使用 WiredTiger 存储引擎的 MVCC 机制
2. 两阶段提交协议（2PC）
3. 维护事务操作日志

ACID 保证：
- 原子性：通过事务操作日志
- 一致性：通过 2PC 协议
- 隔离性：通过 MVCC
- 持久性：通过 journal 日志

### 7. 备份恢复
**Q: MongoDB 的物理备份和逻辑备份有什么区别？如何选择合适的备份策略？**

**A:**
物理备份：
- 直接复制数据文件
- 优点：速度快，支持时间点恢复
- 缺点：与存储引擎强相关

逻辑备份：
- 使用 mongodump/mongorestore
- 优点：版本兼容性好，可选择性恢复
- 缺点：速度较慢，资源消耗大

选择策略考虑因素：
1. 数据量大小
2. 可接受的停机时间
3. 恢复时间目标
4. 存储空间限制

