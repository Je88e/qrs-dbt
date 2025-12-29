# 审计跟踪系统使用指南

## 📋 目录
1. [状态变更审计（Snapshots）](#状态变更审计)
2. [逻辑迁移审计（audit_helper）](#逻辑迁移审计)
3. [实际使用案例](#实际使用案例)

---

## 1️⃣ 状态变更审计（Snapshots）

### 功能说明
追踪业务数据的历史变更，实现 SCD Type 2（缓慢变化维度）。

### 已实施的快照
- ✅ `snap_purchase_orders` - 采购订单状态变更
- ✅ `snap_material_receipts` - 物料接收检验状态变更
- ✅ `snap_inspection_requests` - 检验申请状态变更
- ✅ `snap_inspection_tasks` - 检验任务状态变更
- ✅ `snap_change_controls` - 变更控制状态变更
- ✅ `snap_deviations` - 偏差管理状态变更
- ✅ `snap_capas` - CAPA 状态变更

### 运行方式
```bash
# 运行所有快照
dbt snapshot

# 运行特定快照
dbt snapshot --select snap_purchase_orders

# 查看快照结果
dbt run-operation get_snapshot_history --args '{"snapshot_name": "snap_purchase_orders", "unique_key_value": "PO-2024-001"}'
```

### 查询示例
```sql
-- 查询采购订单的状态变更历史
SELECT 
    purchase_order_number,
    order_status,
    valid_from,
    valid_to,
    CASE 
        WHEN valid_to = '9999-12-31' THEN '当前记录'
        ELSE '历史记录'
    END as record_type
FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO-2024-001'
ORDER BY valid_from DESC;

-- 查询某个时间点的订单状态
SELECT 
    purchase_order_number,
    order_status,
    total_amount
FROM snapshots.snap_purchase_orders
WHERE '2024-01-15'::date BETWEEN valid_from AND valid_to
  AND is_deleted = 'False';
```

---

## 2️⃣ 逻辑迁移审计（audit_helper）

### 功能说明
验证数据转换逻辑的正确性，对比源表和目标表的数据一致性。

### 审计类型

#### A. 行级审计（Row-level Audit）
**目的**：检查记录数量是否一致

**文件位置**：
- `analyses/audit/row_audit/audit_purchase_orders_rows.sql`
- `analyses/audit/row_audit/audit_inspection_requests_rows.sql`
- `analyses/audit/row_audit/audit_change_controls_rows.sql`

**运行方式**：
```bash
# 1. 编译审计 SQL
dbt compile --select audit_purchase_orders_rows

# 2. 查看生成的 SQL
cat target/compiled/qrs/analyses/audit/row_audit/audit_purchase_orders_rows.sql

# 3. 在数据库中执行（或使用 dbt run-operation）
psql -h localhost -U postgres -d qrs -f target/compiled/qrs/analyses/audit/row_audit/audit_purchase_orders_rows.sql
```

**输出示例**：
```
| in_a  | in_b  | count | percent_of_total |
|-------|-------|-------|------------------|
| TRUE  | TRUE  | 95    | 95.00            | ← 完全匹配
| TRUE  | FALSE | 3     | 3.00             | ← 仅在源表存在
| FALSE | TRUE  | 2     | 2.00             | ← 仅在目标表存在
```

**结果解读**：
- `in_a=TRUE, in_b=TRUE`: ✅ 完全匹配的记录
- `in_a=TRUE, in_b=FALSE`: ⚠️ 仅在源表（staging）存在，可能被过滤
- `in_a=FALSE, in_b=TRUE`: ⚠️ 仅在目标表（business）存在，可能是计算生成

---

#### B. 列级审计（Column-level Audit）
**目的**：精确定位哪些列的值不匹配

**文件位置**：
- `analyses/audit/column_audit/audit_purchase_orders_columns.sql`
- `analyses/audit/column_audit/audit_inspection_requests_columns.sql`
- `analyses/audit/column_audit/audit_change_controls_columns.sql`

**运行方式**：
```bash
# 1. 编译审计 SQL
dbt compile --select audit_purchase_orders_columns

# 2. 执行生成的 SQL
psql -h localhost -U postgres -d qrs -f target/compiled/qrs/analyses/audit/column_audit/audit_purchase_orders_columns.sql
```

**输出示例**：
```
审计列: total_amount
| column_name  | match_status              | count_records | percent_of_total |
|--------------|---------------------------|---------------|------------------|
| total_amount | ✅: perfect match         | 92            | 92.00            |
| total_amount | ✅: both are null         | 3             | 3.00             |
| total_amount | ❌: values do not match   | 5             | 5.00             |

审计列: order_status
| column_name  | match_status              | count_records | percent_of_total |
|--------------|---------------------------|---------------|------------------|
| order_status | ✅: perfect match         | 98            | 98.00            |
| order_status | ❌: values do not match   | 2             | 2.00             |
```

**结果解读**：
- `✅: perfect match`: 值完全相同
- `✅: both are null`: 两边都是 NULL（可接受）
- `❌: values do not match`: 值不匹配（需要调查）
- `🤷: missing from a/b`: 记录缺失

---

## 3️⃣ 实际使用案例

### 案例 1：验证采购订单数据迁移

**场景**：从 staging 层迁移到 business 层后，验证数据完整性

**步骤**：

1. **运行行级审计**：
```bash
dbt compile --select audit_purchase_orders_rows
psql -h localhost -U postgres -d qrs -f target/compiled/qrs/analyses/audit/row_audit/audit_purchase_orders_rows.sql
```

2. **分析结果**：
   - 如果 `in_a=TRUE, in_b=TRUE` 的比例 >= 99.5%，说明数据迁移成功
   - 如果有 `in_a=TRUE, in_b=FALSE` 的记录，检查是否是预期的过滤逻辑

3. **如果发现问题，运行列级审计**：
```bash
dbt compile --select audit_purchase_orders_columns
psql -h localhost -U postgres -d qrs -f target/compiled/qrs/analyses/audit/column_audit/audit_purchase_orders_columns.sql
```

4. **定位具体问题列**：
   - 查看哪些列的 `values do not match` 比例较高
   - 检查数据转换逻辑是否正确

---

### 案例 2：追踪变更控制审批流程

**场景**：监管审计要求提供变更控制的完整审批历史

**步骤**：

1. **查询特定变更的历史**：
```sql
SELECT 
    change_code,
    change_status,
    valid_from,
    valid_to,
    EXTRACT(DAY FROM (valid_to - valid_from)) as days_in_status
FROM snapshots.snap_change_controls
WHERE change_code = 'CC-2024-001'
ORDER BY valid_from;
```

2. **输出示例**：
```
| change_code  | change_status | valid_from  | valid_to    | days_in_status |
|--------------|---------------|-------------|-------------|----------------|
| CC-2024-001  | 待审批        | 2024-01-01  | 2024-01-05  | 4              |
| CC-2024-001  | 审批中        | 2024-01-05  | 2024-01-10  | 5              |
| CC-2024-001  | 已批准        | 2024-01-10  | 2024-01-20  | 10             |
| CC-2024-001  | 实施中        | 2024-01-20  | 9999-12-31  | (当前)         |
```

3. **生成审计报告**：
```sql
-- 统计各状态停留时间
SELECT 
    change_status,
    COUNT(*) as change_count,
    AVG(EXTRACT(DAY FROM (valid_to - valid_from))) as avg_days
FROM snapshots.snap_change_controls
WHERE valid_to != '9999-12-31'
GROUP BY change_status
ORDER BY avg_days DESC;
```

---

## 🎯 最佳实践

### 1. 定期运行快照
```bash
# 建议在每日凌晨运行
0 2 * * * cd /path/to/dbt && dbt snapshot
```

### 2. 数据迁移前后运行审计
```bash
# 迁移前：记录基线
dbt compile --select audit_purchase_orders_rows
# 执行并保存结果

# 迁移后：对比差异
dbt compile --select audit_purchase_orders_rows
# 执行并对比结果
```

### 3. 监控审计指标
- 行级匹配率 >= 99.5%
- 列级匹配率 >= 99.0%
- 如果低于阈值，触发告警

---

## 📞 支持

如有问题，请联系数据团队或查看：
- dbt 文档：https://docs.getdbt.com/docs/build/snapshots
- audit_helper 文档：https://github.com/dbt-labs/dbt-audit-helper

