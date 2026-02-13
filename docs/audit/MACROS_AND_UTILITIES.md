# 工具宏和运维脚本

> **版本**: 2.0
> **最后更新**: 2026-02-11
> **维护**: Analytics Engineering Team

---

## 1. 索引管理宏

为了保证快照表的查询性能，特别是在数据量增长后，我们提供了一套自动化的索引管理工具。

### `create_snapshot_indexes`

此宏用于为指定的快照表创建标准化的索引集。

**使用方法**:
```bash
dbt run-operation create_snapshot_indexes
```

**创建的索引类型**:
1. **当前记录索引 (`idx_*_current`)**:
   - `WHERE valid_to = '9999-12-31' AND is_deleted = 'False'`
   - 优化最常用的"当前有效数据"查询。
2. **时间范围索引 (`idx_*_valid_range`)**:
   - `(valid_from DESC, valid_to DESC)`
   - 优化历史趋势分析和时间段查询。
3. **主键+时间索引 (`idx_*_key_time`)**:
   - `(key, valid_from DESC)`
   - 优化单条记录的历史轨迹查询。
4. **删除记录索引 (`idx_*_deleted`)**:
   - `WHERE is_deleted = 'True'`
   - 优化审计和数据清理任务。

**配置**:
在 `qrs/macros/utils/create_snapshot_indexes.sql` 中维护需要创建索引的快照列表。

---

## 2. 数据清理宏

为了支持 GDPR/CCPA 等法规的"被遗忘权"以及维护数据库健康，我们实现了一套软删除检测和归档机制。

### `cleanup_post_hook`

这是一个 dbt `post-hook` 宏，配置在快照模型中。它会在快照运行后自动检测被标记为 `is_deleted=True` 的记录，并将它们加入待处理队列。

**配置示例**:
```sql
{{
    config(
        post_hook="{{ cleanup_post_hook(
            snapshot_name='snap_purchase_orders',
            source_schema='raw',
            source_table='erp_purchase_orders',
            primary_key='purchase_order_number'
        ) }}"
    )
}}
```

### `create_cleanup_pending_queue`

初始化清理队列的基础设施表。

**使用方法**:
```bash
dbt run-operation create_cleanup_pending_queue
```

**创建的表**: `audit.cleanup_pending_queue`
- 存储待处理的删除请求
- 包含 `snapshot_name`, `record_id`, `detected_at`, `status` 等字段

---

## 3. 查询辅助宏

简化对快照表的查询，屏蔽 SCD Type 2 的复杂性。

### `get_current_snapshot`

快速获取指定时间点的快照状态。

**参数**:
- `table_ref`: 快照表引用
- `at_timestamp`: (可选) 查询时间点，默认为当前时间

**示例 SQL**:
```sql
SELECT * FROM {{ get_current_snapshot(ref('snap_purchase_orders')) }}
-- 等同于
SELECT * FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31' AND is_deleted = 'False'
```

### `get_snapshot_history`

获取特定记录的变更历史。

**参数**:
- `table_ref`: 快照表引用
- `key_column`: 主键列名
- `key_value`: 主键值

**示例 SQL**:
```sql
SELECT * FROM {{ get_snapshot_history(ref('snap_purchase_orders'), 'purchase_order_number', 'PO-2026-001') }}
```

---

## 4. 审计与测试宏

用于验证数据完整性和合规性。

### `execute_row_audit`

对特定行进行完整性审计，检查版本链是否连续。

**检查项**:
- `valid_from < valid_to`
- 下一版本的 `valid_from` 等于当前版本的 `valid_to`
- 无重叠时间段

### `execute_compiled_audit`

运行编译后的审计规则集，生成审计报告。

---

## 5. 运维最佳实践

1. **定期运行索引维护**:
   建议每周运行一次 `create_snapshot_indexes` 以确保索引碎片得到整理（部分数据库需要额外的 REINDEX 操作，此宏主要用于确立索引存在）。

2. **监控清理队列**:
   定期查询 `audit.cleanup_pending_queue` 表，监控积压的删除请求。

3. **版本链检查**:
   使用 `execute_row_audit` 定期抽检高频变更的记录，确保 SCD Type 2 逻辑未被破坏。
