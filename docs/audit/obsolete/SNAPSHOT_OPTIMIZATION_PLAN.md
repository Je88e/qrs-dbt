# Snapshot SCD Type 2 优化实施计划

> 基于《配置 Snapshot 以实现 SCD Type 2 的最佳实践》文档的差距分析与改进方案

---

## 1. 现状评估

### 1.1 当前 Snapshot 清单

| Snapshot | 领域 | 主键 | 源模型 |
|----------|------|------|--------|
| `snap_purchase_orders` | ERP | `purchase_order_number` | `stg_purchase_order` |
| `snap_material_receipts` | ERP | `receipt_id` | `stg_material_receipt` |
| `snap_inspection_requests` | LIMS | `request_id` | `stg_inspection_request` |
| `snap_inspection_tasks` | LIMS | `task_id` | `stg_inspection_task` |
| `snap_change_controls` | QMS | `change_id` | `stg_change_control` |
| `snap_deviations` | QMS | `deviation_id` | `stg_deviation` |
| `snap_capas` | QMS | `capa_id` | `stg_capa` |

### 1.2 已符合最佳实践 ✅

| 配置项 | 状态 | 说明 |
|--------|------|------|
| 架构层级 | ✅ | 全部基于 Staging 层构建 |
| 策略选择 | ✅ | 统一使用 `timestamp` 策略 |
| 硬删除追踪 | ✅ | 配置 `hard_deletes='new_record'` |
| 远未来日期 | ✅ | 配置 `dbt_valid_to_current="'9999-12-31'::date"` |
| 元数据列重命名 | ✅ | 统一配置 `snapshot_meta_column_names` |
| 索引宏 | ✅ | 已创建 `create_snapshot_indexes` 宏 |

### 1.3 需要优化的问题 ⚠️

| 问题 | 影响 | 优先级 |
|------|------|--------|
| 缺少 `update_date` 审计字段 | 6/7 个 snapshot 缺失，无法追踪业务更新时间 | P1 |
| 索引宏布尔值语法错误 | `is_deleted = 'False'/'True'` 应为 `is_deleted = false/true` | P1 |
| 缺少下游封装视图 | 下游查询需重复编写过滤逻辑 | P2 |
| 缺少 snapshot 使用文档 | 开发者不清楚如何正确引用 | P3 |

---

## 2. 优化任务清单

### 2.1 P1 - 补充 `update_date` 审计字段

**问题描述**：除 `snap_purchase_orders` 外，其他 6 个 snapshot 均未包含 `update_date` 字段，无法追踪源记录的业务更新时间。

**修改文件**：

| 文件 | 修改内容 |
|------|----------|
| `qrs/snapshots/snap_capas.sql` | 添加 `coalesce(update_date, create_date) as update_date` |
| `qrs/snapshots/snap_deviations.sql` | 添加 `coalesce(update_date, create_date) as update_date` |
| `qrs/snapshots/snap_change_controls.sql` | 添加 `coalesce(update_date, create_date) as update_date` |
| `qrs/snapshots/snap_material_receipts.sql` | 添加 `coalesce(update_date, create_date) as update_date` |
| `qrs/snapshots/snap_inspection_requests.sql` | 添加 `create_date` 和 `update_date` 字段 |
| `qrs/snapshots/snap_inspection_tasks.sql` | 添加 `coalesce(update_date, create_date) as update_date` |

**代码模式**（参考 `snap_purchase_orders`）：
```sql
-- 审计字段
create_date,
-- 处理 NULL 值：如果 update_date 为 NULL，使用 create_date
coalesce(update_date, create_date) as update_date
```

---

### 2.2 P1 - 修复索引宏布尔值语法

**问题描述**：`create_snapshot_indexes.sql` 中使用 `is_deleted = 'False'/'True'`，PostgreSQL 布尔类型应使用 `false/true`。

**修改文件**：`qrs/macros/audit/create_snapshot_indexes.sql`

**修改内容**：

```sql
-- 索引 1: 当前记录查询优化（部分索引，最高优先级）
-- 修改前
WHERE valid_to = '9999-12-31' AND is_deleted = 0;
-- 修改后
WHERE valid_to = '9999-12-31' AND is_deleted = 'False';

-- 索引 4: 删除记录查询（审计需求）
-- 修改前
WHERE is_deleted = 1;
-- 修改后
WHERE is_deleted = 'True';
```

---

### 2.3 P2 - 创建下游封装视图

**目的**：为每个 snapshot 创建「当前状态视图」，简化下游查询逻辑。

**新建文件**：`qrs/models/audit/` 目录下创建封装模型

| 模型名 | 源 Snapshot | 用途 |
|--------|-------------|------|
| `current_purchase_orders.sql` | `snap_purchase_orders` | 获取采购订单当前状态 |
| `current_material_receipts.sql` | `snap_material_receipts` | 获取物料接收当前状态 |
| `current_inspection_requests.sql` | `snap_inspection_requests` | 获取检验申请当前状态 |
| `current_inspection_tasks.sql` | `snap_inspection_tasks` | 获取检验任务当前状态 |
| `current_change_controls.sql` | `snap_change_controls` | 获取变更控制当前状态 |
| `current_deviations.sql` | `snap_deviations` | 获取偏差当前状态 |
| `current_capas.sql` | `snap_capas` | 获取 CAPA 当前状态 |

**代码模板**：
```sql
{{ config(materialized='view') }}

/*
    当前状态视图: current_purchase_orders
    描述: 获取采购订单的最新状态（排除已删除记录）

    使用场景:
    - 下游模型需要获取订单当前状态时使用此视图
    - 避免在每个模型中重复编写 valid_to 过滤逻辑
*/

select
    *
from {{ ref('snap_purchase_orders') }}
where valid_to = '9999-12-31'::date
  and is_deleted = false
```

**配置文件**：创建 `qrs/models/audit/_audit_models.yml`
```yaml
version: 2

models:
  - name: current_purchase_orders
    description: 采购订单当前状态视图（基于 SCD Type 2 快照）
    columns:
      - name: purchase_order_number
        description: 采购订单号（主键）
        data_tests:
          - unique
          - not_null
```

---

### 2.4 P3 - 补充快照使用指南

**新建文件**：更新 `docs/audit/README_SNAPSHOT_USAGE.md`

**内容大纲**：
1. 查询当前状态（使用 `current_*` 视图）
2. 查询历史某时刻状态（Point-in-Time 查询模式）
3. 事实表关联维度快照（范围 JOIN 模式）
4. 索引执行命令

---

## 3. 实施步骤

### Phase 1: 修复核心问题（P1）

```bash
# Step 1: 修改 6 个 snapshot 文件，添加 update_date 字段
# 涉及文件见 2.1 节

# Step 2: 修复索引宏布尔值
# 涉及文件: qrs/macros/audit/create_snapshot_indexes.sql

# Step 3: 验证编译
dbt compile --select snap_*

# Step 4: 执行快照（注意：新增字段会自动 ALTER TABLE）
dbt snapshot

# Step 5: 重建索引
dbt run-operation create_snapshot_indexes
```

### Phase 2: 创建封装视图（P2）

```bash
# Step 1: 创建 qrs/models/audit/ 目录（如不存在）
mkdir -p qrs/models/audit

# Step 2: 创建 7 个 current_* 视图模型

# Step 3: 创建 _audit_models.yml 配置文件

# Step 4: 验证并运行
dbt run --select current_*
dbt test --select current_*
```

### Phase 3: 文档更新（P3）

```bash
# 更新快照使用指南文档
```

---

## 4. 验证清单

### 4.1 编译验证
```bash
dbt compile --select snap_*
dbt compile --select current_*
```

### 4.2 快照执行验证
```bash
dbt snapshot --select snap_purchase_orders
# 确认 update_date 字段已添加到表结构
```

### 4.3 索引验证
```sql
-- 在 PostgreSQL 中执行
SELECT indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'snapshots';
```

### 4.4 测试验证
```bash
dbt test --select snap_*
dbt test --select current_*
```

---

## 5. 风险与注意事项

| 风险 | 缓解措施 |
|------|----------|
| 新增字段导致历史记录该字段为 NULL | 预期行为，不影响功能。文档中说明即可 |
| Staging 层缺少 update_date 字段 | 所有 staging 模型已包含 `loaded_at`，可作为备选 |
| 索引重建耗时 | 在低峰期执行，使用 `CREATE INDEX IF NOT EXISTS` 确保幂等 |

---

## 6. 附录：修改文件清单

| 文件路径 | 操作 | 优先级 |
|----------|------|--------|
| `qrs/snapshots/snap_capas.sql` | 修改 | P1 |
| `qrs/snapshots/snap_deviations.sql` | 修改 | P1 |
| `qrs/snapshots/snap_change_controls.sql` | 修改 | P1 |
| `qrs/snapshots/snap_material_receipts.sql` | 修改 | P1 |
| `qrs/snapshots/snap_inspection_requests.sql` | 修改 | P1 |
| `qrs/snapshots/snap_inspection_tasks.sql` | 修改 | P1 |
| `qrs/macros/audit/create_snapshot_indexes.sql` | 修改 | P1 |
| `qrs/models/audit/current_purchase_orders.sql` | 新建 | P2 |
| `qrs/models/audit/current_material_receipts.sql` | 新建 | P2 |
| `qrs/models/audit/current_inspection_requests.sql` | 新建 | P2 |
| `qrs/models/audit/current_inspection_tasks.sql` | 新建 | P2 |
| `qrs/models/audit/current_change_controls.sql` | 新建 | P2 |
| `qrs/models/audit/current_deviations.sql` | 新建 | P2 |
| `qrs/models/audit/current_capas.sql` | 新建 | P2 |
| `qrs/models/audit/_audit_models.yml` | 新建 | P2 |

---

*文档创建日期: 2026-02-09*
*基于: docs/audit/配置 Snapshot 以实现 SCD Type 2 的最佳实践.md*
