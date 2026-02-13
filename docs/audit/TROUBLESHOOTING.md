# QRS 审计系统故障排查指南

> **版本**: 2.0
> **最后更新**: 2026-02-11
> **维护**: Analytics Engineering Team

---

## 1. 诊断流程

当发现审计数据异常或快照任务失败时，请遵循以下诊断流程：

1. **检查 dbt 日志**: 查看 `logs/dbt.log` 获取详细报错信息。
2. **验证源数据**: 确认源表数据是否正常（主键是否唯一，时间戳是否正确）。
3. **运行测试**: 使用 `dbt test --select <snapshot_name>` 检查数据完整性。
4. **查阅本指南**: 对照下文的常见问题进行处理。

---

## 2. 常见错误处理

### 2.1 Error: duplicate key value violates unique constraint
**现象**: `dbt snapshot` 运行失败，提示主键冲突。
**原因**: 源表中存在重复的主键值（`unique_key`）。dbt snapshot 严格要求源数据的 `unique_key` 必须唯一。
**解决方案**:
1. 找出源表中的重复记录：
   ```sql
   SELECT id, count(*)
   FROM raw.source_table
   GROUP BY id
   HAVING count(*) > 1
   ```
2. 清理源数据或修改 `unique_key` 配置（例如使用复合主键）。

### 2.2 Schema Change Detected
**现象**: 警告或错误提示源表 Schema 与快照表不一致。
**原因**: 源表增加了新列或修改了列类型。
**解决方案**:
- **新增列**: 通常无需干预，dbt 会自动处理。
- **列类型变更**: 
  - 如果变更不兼容（如 text -> int），需手动修改快照表列类型。
  - 如果 dbt 未自动处理，尝试运行一次全量刷新（注意：会丢失历史！仅限非生产环境）。

### 2.3 Snapshot taking too long
**现象**: 快照任务运行时间显著增加。
**原因**: 
- 快照表数据量过大。
- `strategy='check'` 且检查列未建立索引。
- 数据库锁争用。
**解决方案**:
1. 运行 `dbt run-operation create_snapshot_indexes` 优化索引。
2. 检查源表是否进行了全量更新（导致 dbt 认为所有行都变了）。
3. 考虑对历史悠久的快照表进行归档（Archive）。

---

## 3. 数据异常问题

### 3.1 历史记录缺失
**现象**: 源表数据变了，但快照表中只有最新一条记录，没有生成历史版本。
**原因**:
- `strategy='timestamp'` 配置下，源表的 `updated_at` 字段未更新。
- `strategy='check'` 配置下，变更的列不在 `check_cols` 列表中。
**解决方案**:
- 确认源系统的更新机制，确保 `updated_at` 准确反映最后修改时间。
- 如果源系统不可靠，改用 `strategy='check'` 并覆盖所有业务字段。

### 3.2 版本爆炸 (Version Explosion)
**现象**: 某条记录在短时间内生成了大量快照版本。
**原因**:
- 源表有个字段在不断变化（如 `last_sync_time` 或高频浮动的小数）。
- ETL 过程导致的时间戳微小差异。
**解决方案**:
- 在 snapshot 查询中排除非业务字段。
- 使用 `check` 策略并显式指定关注的业务列，避开干扰列。

### 3.3 无法识别删除
**现象**: 源表删除了记录，但快照表中 `is_deleted` 仍为 `False`，且 `valid_to` 未更新。
**原因**: dbt snapshot 默认配置下，如果源表是全量刷新（table）而非增量（incremental/CDC），dbt 可以识别删除。但如果源查询使用了 `WHERE` 过滤，可能会导致误判。
**解决方案**:
- 检查 `snapshot` 定义中的 `select` 语句，确保包含了所有应有的记录。
- 确认配置了 `invalidate_hard_deletes=True` (默认行为)。

---

## 4. 常用调试 SQL

### 检查最近生成的快照
```sql
SELECT *
FROM snapshots.snap_purchase_orders
WHERE dbt_updated_at > NOW() - INTERVAL '1 hour'
ORDER BY dbt_updated_at DESC
LIMIT 100;
```

### 检查特定记录的所有版本
```sql
SELECT snapshot_id, valid_from, valid_to, is_deleted, *
FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO-XYZ-123'
ORDER BY valid_from;
```

---

## 5. 联系支持

如果遇到无法解决的问题，请收集以下信息并联系 Analytics Engineering Team：
1. 失败任务的 `dbt.log` 片段。
2. 涉及的 snapshot 配置文件 (`.sql`)。
3. 源表和目标表的 Schema 定义。
