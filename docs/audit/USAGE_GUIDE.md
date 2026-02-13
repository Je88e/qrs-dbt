# QRS 审计数据使用指南

> **版本**: 2.0
> **最后更新**: 2026-02-11
> **维护**: Analytics Engineering Team

---

## 1. 简介

本指南旨在帮助数据分析师、工程师和业务用户有效地查询和使用 QRS 系统的审计追踪数据。我们的系统采用 SCD Type 2 (Slowly Changing Dimension Type 2) 策略，这意味着我们保留了所有数据的历史变更记录。

---

## 2. 基础查询模式

### 2.1 查询当前状态

这是最常见的查询场景，仅获取每条记录的最新有效状态。

**SQL 模式**:
```sql
SELECT *
FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31'::date  -- 筛选当前有效记录
  AND is_deleted = 'False'           -- 排除已删除记录
```

**dbt 宏方式**:
```sql
-- 在 dbt 模型中推荐使用
SELECT * FROM {{ get_current_snapshot(ref('snap_purchase_orders')) }}
```

### 2.2 时点查询 (Time Travel)

查询数据在过去某个特定时间点的状态（例如：上个月底的库存快照）。

**SQL 模式**:
```sql
-- 查询 2026年1月31日 23:59:59 时的状态
SELECT *
FROM snapshots.snap_inventory
WHERE valid_from <= '2026-01-31 23:59:59'
  AND (valid_to > '2026-01-31 23:59:59' OR valid_to IS NULL)
```

### 2.3 查询变更历史

查看某条特定记录的所有变更历史。

**SQL 模式**:
```sql
SELECT
    purchase_order_number,
    order_status,
    total_amount,
    valid_from,
    valid_to,
    is_deleted
FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO-2026-001'
ORDER BY valid_from DESC
```

**dbt 宏方式**:
```sql
SELECT *
FROM {{ get_snapshot_history('snap_purchase_orders', 'purchase_order_number', 'PO-2026-001') }}
```

---

## 3. 高级查询场景

### 3.1 变更分析 (Change Analysis)

分析状态变更的频率或特定字段的变更。

**示例：统计各采购订单的状态变更次数**:
```sql
SELECT
    purchase_order_number,
    COUNT(*) - 1 as change_count  -- 减1是因为第一条是创建，不算变更
FROM snapshots.snap_purchase_orders
GROUP BY purchase_order_number
HAVING COUNT(*) > 1
ORDER BY change_count DESC
```

**示例：查找谁修改了特定字段**:
```sql
-- 使用 lag 窗口函数对比前后值
WITH changes AS (
    SELECT
        purchase_order_number,
        total_amount,
        LAG(total_amount) OVER (PARTITION BY purchase_order_number ORDER BY valid_from) as prev_amount,
        valid_from as change_time
    FROM snapshots.snap_purchase_orders
)
SELECT *
FROM changes
WHERE total_amount != prev_amount
```

### 3.2 关联快照表

关联两个 SCD Type 2 表比较复杂，因为它们的时间段可能不对齐。通常建议先将它们分别还原到同一时间点，或者使用范围连接（Range Join）。

**推荐方式：基于时间点的关联**:
```sql
-- 查找某时刻的订单及其对应的供应商状态
SELECT
    po.purchase_order_number,
    po.order_status,
    s.supplier_name,
    s.risk_rating
FROM snapshots.snap_purchase_orders po
JOIN snapshots.snap_supplier_master s
  ON po.supplier_id = s.supplier_id
WHERE
    -- 设定统一的查询时间点
    po.valid_from <= '2026-02-01' AND po.valid_to > '2026-02-01'
    AND s.valid_from <= '2026-02-01' AND s.valid_to > '2026-02-01'
```

---

## 4. 理解元数据字段

| 字段名 | 含义 | 用途 |
|--------|------|------|
| `dbt_scd_id` / `snapshot_id` | 记录唯一标识 | 每一行历史记录的唯一ID（主键+哈希） |
| `dbt_updated_at` | dbt 处理时间 | 用于调试 ETL 延迟 |
| `valid_from` | 生效时间 | 业务上的生效时间（源自 `updated_at`） |
| `valid_to` | 失效时间 | 业务上的失效时间（下条记录的 `valid_from`） |
| `is_deleted` | 删除标记 | `True` 表示源系统中该记录已被删除 |

---

## 5. 最佳实践

1. **始终过滤 `is_deleted`**:
   除非你在做审计调查，否则在查询当前状态时永远记得加上 `AND is_deleted = 'False'`。

2. **注意时区**:
   快照中的时间通常统一为 UTC 或系统服务器时间。在进行跨时区分析时请注意转换。

3. **性能优化**:
   - 对于频繁查询的大表，利用 `snapshot_id` 或 `(unique_key, valid_from)` 进行过滤。
   - 尽量避免全表扫描历史记录，使用 `valid_to = '9999-12-31'` 过滤出当前数据通常能利用索引。

4. **处理 NULL 值**:
   `valid_to` 为 `NULL` 的情况在某些数据库实现中可能代表"当前有效"，但在本系统中我们统一将其置为 `9999-12-31` 以简化查询（避免 `OR IS NULL` 逻辑）。
