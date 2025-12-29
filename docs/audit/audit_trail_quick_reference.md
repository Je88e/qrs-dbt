# 审计跟踪系统快速参考卡片

本文档提供审计跟踪系统的快速参考，适合日常开发和运维使用。

---

## 🚀 常用命令

### 快照操作

```bash
# 运行所有快照
dbt snapshot

# 运行特定快照
dbt snapshot --select snap_purchase_orders

# 运行特定标签的快照
dbt snapshot --select tag:erp

# 全量刷新快照（慎用！）
dbt snapshot --full-refresh --select snap_purchase_orders
```

### 审计操作

```bash
# 编译审计模型
dbt compile --select audit_purchase_orders_rows

# 编译所有审计模型
dbt compile --select tag:audit

# 查看编译后的 SQL
cat target/compiled/qrs/analyses/audit/row_audit/audit_purchase_orders_rows.sql
```

### 测试操作

```bash
# 测试特定快照
dbt test --select snap_purchase_orders

# 测试所有快照
dbt test --select tag:snapshot

# 测试特定测试
dbt test --select test_name:unique_snapshot_id
```

### 维护操作

```bash
# 创建快照索引
dbt run-operation create_snapshot_indexes

# 维护快照表
dbt run-operation maintain_snapshots

# 归档旧数据（7年）
dbt run-operation archive_old_snapshots --args '{retention_years: 7}'
```

---

## 📊 常用查询

### 快照查询

```sql
-- 1. 查询当前有效记录
SELECT *
FROM qrs_snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31'
  AND is_deleted = 'False';

-- 2. 查询特定时间点的记录
SELECT *
FROM qrs_snapshots.snap_purchase_orders
WHERE valid_from <= '2024-01-01'::date
  AND valid_to > '2024-01-01'::date
  AND is_deleted = 'False';

-- 3. 查询记录的完整历史
SELECT *
FROM qrs_snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO-2024-001'
ORDER BY valid_from;

-- 4. 查询状态变更次数
SELECT 
    purchase_order_number,
    count(*) - 1 as change_count
FROM qrs_snapshots.snap_purchase_orders
WHERE is_deleted = 'False'
GROUP BY purchase_order_number
HAVING count(*) > 1
ORDER BY change_count DESC;

-- 5. 查询最近变更的记录
SELECT 
    purchase_order_number,
    order_status,
    valid_from,
    valid_to
FROM qrs_snapshots.snap_purchase_orders
WHERE valid_from >= current_date - interval '7 days'
ORDER BY valid_from DESC;
```

### 监控查询

```sql
-- 1. 检查快照表健康状态
SELECT 
    'snap_purchase_orders' as snapshot_name,
    count(*) as total_records,
    sum(CASE WHEN valid_to = '9999-12-31' THEN 1 ELSE 0 END) as current_records,
    sum(CASE WHEN is_deleted = 'True' THEN 1 ELSE 0 END) as deleted_records,
    pg_size_pretty(pg_total_relation_size('qrs_snapshots.snap_purchase_orders')) as table_size
FROM qrs_snapshots.snap_purchase_orders;

-- 2. 检查时间重叠（不应有结果）
SELECT s1.purchase_order_number
FROM qrs_snapshots.snap_purchase_orders s1
JOIN qrs_snapshots.snap_purchase_orders s2
    ON s1.purchase_order_number = s2.purchase_order_number
    AND s1.snapshot_id != s2.snapshot_id
WHERE s1.valid_from < s2.valid_to
  AND s2.valid_from < s1.valid_to
  AND s1.valid_to != '9999-12-31'
  AND s2.valid_to != '9999-12-31';

-- 3. 检查时间逻辑错误（不应有结果）
SELECT *
FROM qrs_snapshots.snap_purchase_orders
WHERE valid_from >= valid_to
  AND valid_to != '9999-12-31';

-- 4. 检查索引使用情况
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan as index_scans,
    idx_tup_read as tuples_read,
    idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'qrs_snapshots'
ORDER BY idx_scan DESC;
```

---

## 🔧 快照配置模板

### 基础配置

```yaml
version: 2

snapshots:
  - name: snap_table_name
    description: 表描述
    relation: ref('stg_table_name')
    
    config:
      schema: snapshots
      unique_key: primary_key_column
      strategy: timestamp
      updated_at: update_date_column
      hard_deletes: new_record
      dbt_valid_to_current: '9999-12-31'
      tags: ['snapshot', 'system_name']
```

### 高级配置（自定义列名）

```yaml
config:
  schema: snapshots
  unique_key: id
  strategy: timestamp
  updated_at: update_date
  hard_deletes: new_record
  dbt_valid_to_current: '9999-12-31'
  
  snapshot_meta_column_names:
    dbt_valid_from: valid_from
    dbt_valid_to: valid_to
    dbt_scd_id: snapshot_id
    dbt_updated_at: last_updated_at
    dbt_is_deleted: is_deleted
  
  tags: ['snapshot', 'erp']
  
  post-hook:
    - "CREATE INDEX IF NOT EXISTS idx_{{ this.name }}_current 
       ON {{ this }} (id) 
       WHERE valid_to = '9999-12-31' AND is_deleted = 'False'"
```

---

## 🎯 审计宏使用

### 行级审计模板

```sql
{% set old_query %}
select
    id,
    {{ standardize_for_audit('name', 'string') }} as name,
    {{ standardize_for_audit('amount', 'numeric') }} as amount,
    {{ standardize_for_audit('created_at', 'timestamp') }} as created_at
from legacy_schema.table_name
where created_at >= '2024-01-01'
{% endset %}

{% set new_query %}
select
    id,
    {{ standardize_for_audit('name', 'string') }} as name,
    {{ standardize_for_audit('amount', 'numeric') }} as amount,
    {{ standardize_for_audit('created_at', 'timestamp') }} as created_at
from {{ ref('fct_table_name') }}
where created_at >= '2024-01-01'
{% endset %}

{{ audit_helper.compare_queries(
    a_query=old_query,
    b_query=new_query,
    primary_key="id",
    summarize=true
) }}
```

### 列级审计模板

```sql
{% set columns_to_compare = [
    'name',
    'amount',
    'status'
] %}

{{ audit_helper.compare_column_values(
    a_query="select * from legacy_schema.table_name where id = 123",
    b_query="select * from " ~ ref('fct_table_name') ~ " where id = 123",
    primary_key="id",
    column_to_compare=columns_to_compare
) }}
```

---

## 📋 故障排查清单

### 快照失败

**问题**: 快照运行失败

**检查步骤**:
1. 检查源表是否存在
2. 检查 `updated_at` 列是否存在且有值
3. 检查 `unique_key` 是否唯一
4. 检查数据库权限

**解决方案**:
```bash
# 查看详细错误
dbt snapshot --select snap_table_name --debug

# 检查源表
dbt run --select stg_table_name
```

### 审计匹配率低

**问题**: 匹配率 < 95%

**检查步骤**:
1. 检查行数是否一致
2. 检查主键是否一致
3. 检查数据类型是否一致
4. 检查 NULL 值处理

**解决方案**:
```sql
-- 对比行数
SELECT 'old' as source, count(*) FROM legacy_schema.table_name
UNION ALL
SELECT 'new' as source, count(*) FROM fct_table_name;

-- 查找缺失记录
SELECT id FROM legacy_schema.table_name
EXCEPT
SELECT id FROM fct_table_name;
```

### 性能问题

**问题**: 查询缓慢

**检查步骤**:
1. 检查索引是否存在
2. 检查表膨胀率
3. 检查统计信息

**解决方案**:
```sql
-- 检查索引
SELECT * FROM pg_indexes 
WHERE tablename = 'snap_purchase_orders';

-- 执行 VACUUM
VACUUM ANALYZE qrs_snapshots.snap_purchase_orders;

-- 重建索引
REINDEX TABLE CONCURRENTLY qrs_snapshots.snap_purchase_orders;
```

---

## 📞 获取帮助

- **文档**: 查看 [`README_audit_trail.md`](./README_audit_trail.md)
- **示例**: 查看 [`audit_trail_code_examples.md`](./audit_trail_code_examples.md)
- **详细方案**: 查看 [`audit_trail_implementation_plan.md`](./audit_trail_implementation_plan.md)

---

**最后更新**: 2024-12-24

