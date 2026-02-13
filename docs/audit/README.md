# QRS 审计追踪系统 - 技术文档

> **版本**: 2.0
> **最后更新**: 2026-02-11
> **维护**: Analytics Engineering Team

---

## 📋 目录

1. [系统概述](#系统概述)
2. [快照模块详解](./SNAPSHOT_ARCHITECTURE.md)
3. [工具宏和运维](./MACROS_AND_UTILITIES.md)
4. [使用指南](./USAGE_GUIDE.md)
5. [运维手册](./OPERATIONS_MANUAL.md)
6. [故障排查](./TROUBLESHOOTING.md)

---

## 系统概述

### 架构设计理念

QRS 审计追踪系统基于 **dbt Snapshots** 实现，采用 **SCD Type 2 (Slowly Changing Dimension)** 策略，确保符合 GxP 法规要求的数据可审计性和可追溯性。

**核心特性**:
- ✅ **永久保留**: 所有状态变更历史永久保存
- ✅ **时点查询**: 支持查询任意时间点的数据状态
- ✅ **硬删除追踪**: 源系统删除的记录会在快照中标记（`is_deleted=True`）
- ✅ **GxP 合规**: 满足 FDA 21 CFR Part 11 和 EU Annex 11 要求

---

## 系统范围

### 覆盖的源系统

| 源系统 | 快照数量 | 主要业务领域 | 更新频率 |
|--------|---------|-------------|---------|
| **ERP** | 12 | 采购、库存、配方 | 每日 |
| **MES** | 10 | 生产、设备、人员 | 每日 |
| **LIMS** | 9 | 检验、样品、质量标准 | 每4小时（高频） |
| **QMS** | 9 | 变更、偏差、CAPA、审计 | 每日 |
| **SCADA** | 6 | 设备监控、环境、能耗 | 每小时 |
| **PV** | 3 | 不良反应、投诉、召回 | 每日 |
| **总计** | **49** | - | - |

### 快照分类

#### 1. 高频快照（High-Frequency）
适用于状态变化频繁的业务流程：
- `snap_inspection_requests` - 检验申请（每4小时）
- `snap_inspection_tasks` - 检验任务（每4小时）
- `snap_alarm` - SCADA报警（每小时）
- `snap_equipment_data` - 设备运行数据（每小时）
- `snap_batch_tracking` - 批次追踪（每小时）

#### 2. 日频快照（Daily）
适用于常规业务流程和主数据：
- 所有 ERP、QMS、PV 快照
- 大部分 MES、LIMS 快照

---

## 技术架构

### 1. 快照存储策略

```
源系统 (raw schema)
    ↓
Staging 层 (stg_* tables)
    ↓
Snapshots 层 (snapshots schema) ← SCD Type 2
    ↓
Utility 层 (current_* views)
    ↓
Business 层 (fct_*, dim_*)
```

### 2. 元数据字段

所有快照表包含以下 SCD Type 2 元数据字段：

| 字段名 | 类型 | 说明 | 示例值 |
|--------|------|------|--------|
| `dbt_valid_from` → `valid_from` | `timestamp` | 记录生效时间 | `2026-01-15 08:30:00` |
| `dbt_valid_to` → `valid_to` | `date` | 记录失效时间 | `9999-12-31`（当前记录）<br>`2026-02-10`（历史记录） |
| `dbt_scd_id` → `snapshot_id` | `text` | 快照唯一标识符 | `abc123def456...` |
| `dbt_updated_at` → `last_updated_at` | `timestamp` | 最后更新时间 | `2026-02-11 10:45:00` |
| `dbt_is_deleted` → `is_deleted` | `text` | 删除标记 | `'True'` / `'False'` |

### 3. 快照策略配置

#### Timestamp 策略（主流）
```sql
{% snapshot snap_purchase_orders %}
{{
    config(
        target_schema='snapshots',
        unique_key='purchase_order_number',
        strategy='timestamp',
        updated_at='loaded_at',
        hard_deletes='new_record',
        dbt_valid_to_current="'9999-12-31'::date",
        snapshot_meta_column_names={
            'dbt_scd_id': 'snapshot_id'
        }
    )
}}

select * from {{ ref('stg_purchase_order') }}
{% endsnapshot %}
```

**适用场景**: 源表有可靠的 `updated_at` 或 `loaded_at` 字段

#### Check 策略（备选）
```sql
config(
    strategy='check',
    check_cols=['order_status', 'total_amount']
)
```

**适用场景**: 源表无时间戳字段，需要基于特定列的值变化判断

---

## 数据流程

### 1. 快照生成流程

```mermaid
graph LR
    A[源系统] -->|CDC/ETL| B[raw schema]
    B -->|dbt run| C[stg_* models]
    C -->|dbt snapshot| D[snapshots schema]
    D -->|current_* views| E[utility层]
    E -->|dbt run| F[business层]
```

### 2. 状态变更追踪示例

以采购订单为例：

| snapshot_id | purchase_order_number | order_status | valid_from | valid_to | is_deleted |
|-------------|----------------------|-------------|-----------|---------|-----------|
| `abc123...` | `PO-2026-001` | 待审批 | 2026-01-10 08:00 | 2026-01-12 | False |
| `def456...` | `PO-2026-001` | 已审批 | 2026-01-12 14:30 | 2026-01-15 | False |
| `ghi789...` | `PO-2026-001` | 进行中 | 2026-01-15 09:00 | 2026-02-01 | False |
| `jkl012...` | `PO-2026-001` | 已完成 | 2026-02-01 16:00 | 9999-12-31 | False |

**查询任意时点状态**:
```sql
-- 查询 2026-01-13 时的订单状态
SELECT *
FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO-2026-001'
  AND valid_from <= '2026-01-13'
  AND valid_to > '2026-01-13'
-- 结果: order_status = '已审批'
```

---

## 合规性保障

### GxP 要求覆盖

| 要求 | 实现方式 | 证据 |
|------|---------|------|
| **数据完整性** | 所有变更均保留 | SCD Type 2 历史表 |
| **可审计性** | 元数据字段完整 | `valid_from/to`, `snapshot_id` |
| **防篡改** | 快照表只增不减 | 仅允许 INSERT 操作 |
| **硬删除追踪** | `is_deleted` 标记 | 删除记录标记为 `True` 而非物理删除 |
| **时点查询** | SCD Type 2 支持 | 通过 `valid_from/to` 范围查询 |

---

## 快速开始

### 运行快照更新
```bash
# 运行所有快照
dbt snapshot

# 运行特定快照
dbt snapshot --select snap_purchase_orders

# 运行特定标签的快照
dbt snapshot --select tag:high_frequency
dbt snapshot --select tag:qms
```

### 查询当前状态
```sql
-- 方式1: 使用 utility 视图（推荐）
SELECT * FROM {{ ref('current_purchase_orders') }}

-- 方式2: 直接查询快照表
SELECT * FROM snapshots.snap_purchase_orders
WHERE valid_to = '9999-12-31'::date
  AND is_deleted = 'False'
```

### 查询历史状态
```sql
-- 查询某条记录的所有变更历史
SELECT
    purchase_order_number,
    order_status,
    valid_from,
    valid_to,
    is_deleted
FROM snapshots.snap_purchase_orders
WHERE purchase_order_number = 'PO-2026-001'
ORDER BY valid_from DESC
```

---

## 存储和性能

### 存储规模估算

| 快照类型 | 平均记录数 | 日增长记录 | 年存储增长 |
|---------|----------|----------|-----------|
| 高频快照 | 10,000 | ~500 | ~180,000 |
| 日频快照 | 50,000 | ~200 | ~73,000 |

### 性能优化措施

1. **索引优化**: 使用 `create_snapshot_indexes` 宏
2. **分区策略**: 按 `valid_from` 进行日期分区（未来考虑）
3. **归档策略**: 已删除记录定期归档（通过 cleanup macros）

---

## 相关文档

- **[快照架构详解](./SNAPSHOT_ARCHITECTURE.md)** - 深入了解 49 个快照的业务含义和配置
- **[工具宏和运维](./MACROS_AND_UTILITIES.md)** - 运维宏、清理工具、索引管理
- **[使用指南](./USAGE_GUIDE.md)** - 常见查询场景和最佳实践
- **[运维手册](./OPERATIONS_MANUAL.md)** - 日常运维、监控、备份恢复
- **[故障排查](./TROUBLESHOOTING.md)** - 常见问题和解决方案

---

## 变更历史

| 版本 | 日期 | 变更说明 |
|------|------|---------|
| 2.0 | 2026-02-11 | 重构审计系统，扩展至 49 个快照，统一配置 |
| 1.0 | 2025-12-01 | 初始版本，7 个核心快照 |

---

## 联系方式

如有疑问或需要支持，请联系：
- **Analytics Engineering Team**: analytics-eng@novatech.com
- **项目仓库**: [QRS dbt Repository](https://github.com/novatech/qrs-dbt)
