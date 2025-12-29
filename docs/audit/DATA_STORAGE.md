# 审计数据存储位置说明

## 📊 数据存储架构

```
PostgreSQL 数据库 (postgres)
│
├── public schema (业务数据)
│   ├── stg_purchase_order (Staging 层)
│   ├── fct_purchase_orders (Business 层)
│   └── ... (其他业务表)
│
├── snapshots schema (审计快照数据) ✅ 物理存储
│   ├── snap_purchase_orders (采购订单历史)
│   ├── snap_material_receipts (物料接收历史)
│   ├── snap_inspection_requests (检验申请历史)
│   ├── snap_inspection_tasks (检验任务历史)
│   ├── snap_change_controls (变更控制历史)
│   ├── snap_deviations (偏差管理历史)
│   └── snap_capas (CAPA 历史)
│
└── (临时查询结果) ⚠️ 不持久化
    └── audit_helper 审计结果 (仅在查询时生成)
```

---

## 1️⃣ 状态变更审计数据（Snapshots）

### 存储位置
- **Schema**: `snapshots`
- **表名**: `snap_*`
- **存储类型**: **物理表**（永久存储）

### 表结构示例
```sql
-- snap_purchase_orders 表结构
CREATE TABLE snapshots.snap_purchase_orders (
    -- 业务字段
    purchase_order_number VARCHAR,
    supplier_id VARCHAR,
    order_type VARCHAR,
    order_status VARCHAR,
    order_date DATE,
    total_amount NUMERIC,
    currency VARCHAR,
    buyer VARCHAR,
    
    -- 审计元数据字段（由 dbt 自动添加）
    valid_from TIMESTAMP,           -- 记录生效时间
    valid_to TIMESTAMP,             -- 记录失效时间（9999-12-31 表示当前记录）
    snapshot_id VARCHAR,            -- 快照唯一标识
    last_updated_at TIMESTAMP,      -- 最后更新时间
    is_deleted VARCHAR              -- 是否已删除（True/False）
);
```

### 数据示例
```
| purchase_order_number | order_status | valid_from          | valid_to            | is_deleted |
|-----------------------|--------------|---------------------|---------------------|------------|
| PO202401001           | 待审批        | 2024-01-05 00:00:00 | 2024-01-06 00:00:00 | False      |
| PO202401001           | 已审批        | 2024-01-06 00:00:00 | 2024-01-10 00:00:00 | False      |
| PO202401001           | 进行中        | 2024-01-10 00:00:00 | 2024-01-15 00:00:00 | False      |
| PO202401001           | 已完成        | 2024-01-15 00:00:00 | 9999-12-31 00:00:00 | False      | ← 当前记录
```

### 查询方式
```sql
-- 查询当前有效记录
SELECT * FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31' AND is_deleted = 'False';

-- 查询历史变更记录
SELECT * FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO202401001'
ORDER BY valid_from;

-- 查询某个时间点的状态
SELECT * FROM snapshots.snap_purchase_orders
WHERE '2024-01-08'::date BETWEEN valid_from AND valid_to;
```

### 索引优化
每个快照表有 4 个索引：
- `idx_{table}_current` - 当前记录查询
- `idx_{table}_valid_range` - 时间范围查询
- `idx_{table}_key_time` - 主键+时间复合查询
- `idx_{table}_deleted` - 删除记录查询

---

## 2️⃣ 逻辑迁移审计数据（audit_helper）

### 存储位置
- **存储类型**: **不持久化**（临时查询结果）
- **输出方式**: 
  - 终端输出
  - 或保存到文件
  - 或导入到审计报告表

### 数据流程
```
1. dbt compile --select audit_purchase_orders_rows
   ↓
2. 生成 SQL 文件: target/compiled/qrs/analyses/audit/row_audit/audit_purchase_orders_rows.sql
   ↓
3. 执行 SQL（手动或自动）
   ↓
4. 获得临时结果集（不保存到数据库）
   ↓
5. 可选：保存到审计报告表
```

### 输出示例
```
-- 行级审计输出
| in_a  | in_b  | count | percent_of_total |
|-------|-------|-------|------------------|
| TRUE  | TRUE  | 95    | 95.00            |
| TRUE  | FALSE | 3     | 3.00             |
| FALSE | TRUE  | 2     | 2.00             |

-- 列级审计输出
| column_name  | match_status              | count_records | percent_of_total |
|--------------|---------------------------|---------------|------------------|
| total_amount | ✅: perfect match         | 92            | 92.00            |
| total_amount | ❌: values do not match   | 5             | 5.00             |
```

### 持久化方案（可选）

如果需要保存审计结果，可以创建审计报告表：

```sql
-- 创建审计报告表
CREATE TABLE audit_reports.row_audit_history (
    audit_id SERIAL PRIMARY KEY,
    audit_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source_table VARCHAR,
    target_table VARCHAR,
    in_a BOOLEAN,
    in_b BOOLEAN,
    record_count INTEGER,
    percent_of_total NUMERIC
);

-- 插入审计结果
INSERT INTO audit_reports.row_audit_history (source_table, target_table, in_a, in_b, record_count, percent_of_total)
SELECT 
    'stg_purchase_order' as source_table,
    'fct_purchase_orders' as target_table,
    in_a,
    in_b,
    count,
    percent_of_total
FROM (
    -- 这里是 audit_helper 生成的 SQL
    ...
);
```

---

## 📈 存储空间管理

### 查看快照表大小
```sql
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS total_size,
    pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) AS table_size,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) AS index_size
FROM pg_tables
WHERE schemaname = 'snapshots'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### 清理历史数据
```sql
-- 删除 1 年前的历史记录（保留当前记录）
DELETE FROM snapshots.snap_purchase_orders
WHERE valid_to < CURRENT_DATE - INTERVAL '1 year'
  AND valid_to != '9999-12-31';

-- 清理已删除的记录
DELETE FROM snapshots.snap_purchase_orders
WHERE is_deleted = 'True'
  AND valid_to < CURRENT_DATE - INTERVAL '6 months';
```

---

## 🔍 数据访问权限

### 推荐权限设置
```sql
-- 审计人员：只读权限
GRANT SELECT ON ALL TABLES IN SCHEMA snapshots TO audit_role;

-- 数据工程师：完全权限
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA snapshots TO data_engineer_role;

-- 业务用户：只能查看当前记录
CREATE VIEW snapshots.v_current_purchase_orders AS
SELECT * FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31' AND is_deleted = 'False';

GRANT SELECT ON snapshots.v_current_purchase_orders TO business_user_role;
```

---

## 📊 监控指标

### 快照表增长监控
```sql
-- 每日新增记录数
SELECT 
    DATE(valid_from) as snapshot_date,
    COUNT(*) as new_records
FROM snapshots.snap_purchase_orders
WHERE valid_from >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE(valid_from)
ORDER BY snapshot_date DESC;

-- 当前有效记录数
SELECT 
    COUNT(*) as current_records,
    COUNT(*) FILTER (WHERE is_deleted = 'True') as deleted_records
FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31';
```

