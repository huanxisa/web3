# PostgreSQL 高级面试题

## 1. MVCC 机制
**问**: 请详细解释 PostgreSQL 的 MVCC 实现机制，以及 xmin、xmax、cmin、cmax 这些系统字段的作用？

**答**: 
- PostgreSQL 通过在每行数据中维护事务 ID (XID) 来实现 MVCC
- xmin: 创建该行的事务 ID
- xmax: 删除该行的事务 ID（如果行未被删除则为 0）
- cmin: 在创建事务中的命令序号
- cmax: 在删除事务中的命令序号
- 通过比较当前事务 ID 与这些系统字段，可以确定数据对当前事务是否可见

## 2. WAL 机制
**问**: WAL(Write-Ahead Logging)的工作原理是什么？在数据库同步场景中如何利用 WAL？

**答**:
- WAL 确保数据修改先写入日志再写入数据文件
- WAL 包含完整的 REDO 信息
- 可用于：
  - 故障恢复
  - 数据复制
  - 时间点恢复
- 在数据同步工具中，可以通过解析 WAL 日志实现实时数据同步

## 3. vacuum 机制
**问**: vacuum 的作用是什么？autovacuum 是如何工作的？

**答**:
- vacuum 主要用于：
  - 回收死元组占用的空间
  - 更新统计信息
  - 防止事务 ID 回卷
- autovacuum 触发条件：
  - 表中死元组数量超过阈值
  - 根据 autovacuum_vacuum_scale_factor 和 autovacuum_vacuum_threshold 计算

## 4. 事务隔离级别
**问**: PostgreSQL 如何实现 Serializable 隔离级别？与其他数据库的实现有什么不同？

**答**:
- PostgreSQL 使用 SSI (Serializable Snapshot Isolation)
- 通过检测读写依赖关系识别可能的序列化异常
- 相比 Oracle 等使用锁实现的方式，具有更好的并发性能

## 5. 物理复制与逻辑复制
**问**: 物理复制和逻辑复制的区别是什么？各自适用于什么场景？

**答**:
- 物理复制：
  - 基于 WAL 日志
  - 完整复制整个数据库集群
  - 适用于灾备和读写分离
- 逻辑复制：
  - 基于 PUBLICATION/SUBSCRIPTION
  - 可以复制指定表
  - 支持跨版本复制
  - 适用于数据集成和迁移

## 6. 索引实现
**问**: PostgreSQL 的 GiST、GIN、BRIN 索引有什么区别？各自适用于什么场景？

**答**:
- GiST (Generalized Search Tree):
  - 平衡树结构
  - 适用于地理数据、全文搜索
- GIN (Generalized Inverted Index):
  - 适用于多值类型（数组、jsonb）
  - 查询快但更新慢
- BRIN (Block Range Index):
  - 适用于有序大数据
  - 索引体积小，维护成本低

## 7. 并行查询
**问**: PostgreSQL 如何实现并行查询？并行度是如何确定的？

**答**:
- 并行查询通过多个工作进程同时处理数据
- 并行度根据以下因素确定：
  - max_parallel_workers_per_gather 参数
  - 表大小
  - CPU 核心数
  - 查询成本估算

## 8. 数据同步性能优化
**问**: 在数据同步工具开发中，如何优化大批量数据同步的性能？

**答**:
- 批量提交事务
- 使用 COPY 命令代替 INSERT
- 同步前禁用索引，同步后重建
- 调整 WAL 相关参数：
  - wal_level
  - max_wal_senders
  - wal_keep_segments
- 使用并行同步策略
- 实现增量同步机制

## 9. 锁机制
**问**: PostgreSQL 的锁机制有哪些？如何处理死锁？

**答**:
- 锁类型：
  - 表级锁
  - 行级锁
  - 页面锁
  - 咨询锁
- 死锁处理：
  - 自动检测
  - 超时回滚
  - wait_event 视图监控

## 10. 性能诊断
**问**: 如何诊断 PostgreSQL 的性能问题？有哪些关键视图和工具？

**答**:
- 关键视图：
  - pg_stat_activity
  - pg_stat_statements
  - pg_locks
- 工具：
  - EXPLAIN ANALYZE
  - auto_explain
  - pg_stat_statements
- 监控指标：
  - 缓存命中率
  - WAL 生成速率
  - 锁等待情况
  - 死元组累积情况


