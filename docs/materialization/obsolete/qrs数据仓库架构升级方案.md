# QRS 数据仓库架构升级方案

## 概述

为 GxP 合规制药数据仓库实施雪花ID生成和增量更新架构升级。

**范围**：
- 44个 Staging 模型：新增 `snowflake_id` 字段 + 转换为 incremental
- 38个事实表（fct_*）：转换为 incremental
- 9个维度表（dim_*）：保持 view 不变

---

## 一、雪花ID实现方案

### 1.1 创建 PostgreSQL 函数（优先）

**新建文件**: `qrs/macros/snowflake/create_snowflake_function.sql`

```sql
{% macro create_snowflake_function() %}

CREATE SEQUENCE IF NOT EXISTS snowflake_seq
    MINVALUE 0 MAXVALUE 4095 CYCLE;

CREATE OR REPLACE FUNCTION generate_snowflake_id(
    machine_id INT DEFAULT {{ var('snowflake_machine_id', 1) }}
) RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    epoch_ms BIGINT := 1704067200000;  -- 2024-01-01 UTC
    current_ms BIGINT;
    seq_id INT;
BEGIN
    current_ms := (EXTRACT(EPOCH FROM clock_timestamp()) * 1000)::BIGINT - epoch_ms;
    seq_id := nextval('snowflake_seq')::INT;
    -- 结构: 41位时间戳 + 10位机器ID + 12位序列号
    RETURN (current_ms << 22) | ((machine_id & 1023) << 12) | (seq_id & 4095);
END;
$$;

{% endmacro %}
```

### 1.2 创建 dbt 宏（降级方案）

**新建文件**: `qrs/macros/snowflake/generate_snowflake_id.sql`

```sql
{% macro generate_snowflake_id() %}
    {% if target.type == 'postgres' %}
        generate_snowflake_id({{ var('snowflake_machine_id', 1) }})
    {% else %}
        (((extract(epoch from now())::bigint * 1000 - 1704067200000) << 22)
         | (({{ var('snowflake_machine_id', 1) }} & 1023) << 12)
         | (floor(random() * 4096)::int))::bigint
    {% endif %}
{% endmacro %}
```

---

## 二、Staging 层改造

### 2.1 增量字段设计

#### 2.1.1 为什么不使用源系统时间戳？

源系统的 `create_date`/`update_date` **不适合**作为增量控制字段：

| 问题 | 说明 |
|------|------|
| Late-arriving data | 数据可能延迟到达 raw 层，源系统时间戳早于实际入库时间 |
| Raw层重新加载 | 历史数据重新导入时，源系统时间戳不变，但需要重新处理 |
| 时钟不同步 | 多个源系统时钟可能存在偏差 |
| 业务 vs 技术时间 | 源系统时间是业务事件时间，非数据处理时间 |

#### 2.1.2 新增 `_loaded_at` 字段

在 Staging 层新增 **dbt 处理时间戳** `_loaded_at`，记录数据从 raw 层加载到 staging 层的时间：

```sql
current_timestamp as _loaded_at
```

**增量控制策略**：

| 层级 | 增量控制字段 | 说明 |
|------|-------------|------|
| Staging | `_loaded_at` | dbt 处理时间，每次增量运行时与 `{{ this }}` 中的 max 值比较 |
| Business (事实表) | 上游 `_loaded_at` | 基于 staging 层的 `_loaded_at` 字段进行增量过滤 |

#### 2.1.3 各系统增量策略

| 系统 | unique_key | 增量策略 | 保留的源系统时间字段 |
|------|-----------|----------|---------------------|
| ERP | 业务主键 | merge | `create_date`, `update_date` |
| MES | 业务主键 | merge | `create_date` |
| LIMS | 业务主键 | merge | `test_date`, `create_date` |
| QMS | 业务主键 | merge | `create_date` |
| SCADA | `data_id` | append | `collection_time` |
| PV | 业务主键 | merge | `create_date` |

> **注意**：源系统时间字段（如 `create_date`、`update_date`）仍需保留，用于业务分析和审计追溯，但**不用于增量控制**。

### 2.2 模型改造模板

**示例**: `qrs/models/staging/stg_purchase_order.sql`

```sql
{{
    config(
        materialized='incremental',
        unique_key='purchase_order_number',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['staging', 'erp', 'procurement']
    )
}}

with source_data as (
    select * from {{ source('erp_raw', 'erp_purchase_order') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }} as snowflake_id,

        -- 原有字段
        po_number as purchase_order_number,
        supplier_id,
        po_type as order_type,
        po_status as order_status,
        order_date,
        expected_delivery_date,
        actual_delivery_date,
        total_amount,
        currency,
        buyer,
        approver,
        approval_date,
        create_date,
        update_date,

        -- 新增：dbt处理时间戳（用于增量控制）
        current_timestamp as _loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}
```

> **说明**：
> - `_loaded_at` 在 `final` CTE 中生成，确保每条记录都有处理时间戳
> - 增量过滤放在最外层 `select`，基于已有记录的 `_loaded_at` 进行比较
> - 使用 `merge` 策略，相同 `unique_key` 的记录会被更新而非重复插入

### 2.3 SCADA 高频数据模板（append策略）

```sql
{{
    config(
        materialized='incremental',
        unique_key='data_id',
        incremental_strategy='append',
        tags=['staging', 'scada', 'monitoring']
    )
}}

with source_data as (
    select * from {{ source('scada_raw', 'scada_equipment_data') }}
),

final as (
    select
        {{ generate_snowflake_id() }} as snowflake_id,
        data_id,
        equipment_id,
        collection_time,
        -- ... 其他字段 ...

        -- 新增：dbt处理时间戳
        current_timestamp as _loaded_at
    from source_data
)

select * from final
{% if is_incremental() %}
where _loaded_at > (
    select coalesce(max(_loaded_at), '1900-01-01'::timestamp)
           - interval '{{ var("high_frequency_lookback_minutes", 2) }} minutes'
    from {{ this }}
)
{% endif %}
```

> **SCADA 特殊处理**：
> - 使用 `append` 策略，不进行 merge（时序数据不更新）
> - 回溯窗口更短（默认2分钟），因为 SCADA 数据实时性要求高

---

## 三、Business 层事实表改造

### 3.1 事实表增量模板（多表Join场景）

**示例**: `qrs/models/business/fct_purchase_orders.sql`

```sql
{{
    config(
        materialized='incremental',
        unique_key='purchase_order_detail_id',
        incremental_strategy='merge',
        on_schema_change='append_new_columns',
        tags=['erp', 'procurement', 'pqr']
    )
}}

with purchase_order as (
    select * from {{ ref('stg_purchase_order') }}
),

purchase_order_detail as (
    select * from {{ ref('stg_purchase_order_detail') }}
),

supplier as (
    select * from {{ ref('stg_supplier_master') }}
),

material as (
    select * from {{ ref('stg_material_master') }}
),

final as (
    select
        -- 新增雪花ID
        {{ generate_snowflake_id() }} as snowflake_id,

        -- 原有字段
        po.purchase_order_number,
        pod.purchase_order_detail_id,
        po.supplier_id,
        s.supplier_name,
        s.supplier_type,
        pod.material_id,
        m.material_name,
        m.material_type,
        m.material_specification,
        po.order_type,
        po.order_status,
        po.order_date,
        po.expected_delivery_date,
        po.actual_delivery_date,
        pod.quantity as order_quantity,
        pod.unit,
        pod.unit_price,
        pod.amount as line_amount,
        po.total_amount,
        po.currency,
        pod.delivered_quantity,
        pod.inspection_status,
        po.buyer,
        po.approver,
        po.approval_date,
        po.create_date,
        po.update_date,

        -- 使用上游staging层的_loaded_at作为增量控制
        greatest(po._loaded_at, pod._loaded_at) as _loaded_at

    from purchase_order po
    left join purchase_order_detail pod on po.purchase_order_number = pod.purchase_order_number
    left join supplier s on po.supplier_id = s.supplier_id
    left join material m on pod.material_id = m.material_id
)

select * from final
{% if is_incremental() %}
where loaded_at > (
    select coalesce(max(loaded_at), CAST('1900-01-01 00:00:00.000 +0800' AS timestamptz))
           - interval '{{ var("incremental_lookback_minutes", 5) }} minutes'
    from {{ this }}
)
{% endif %}
```

> **Business 层增量控制说明**：
> - 使用 `greatest(po._loaded_at, pod._loaded_at)` 取多个上游表的最大处理时间
> - 确保任一上游表有新数据时，事实表都能正确更新
> - 维度表（dim_*）保持 view，无需 `_loaded_at` 字段

---

## 四、dbt_project.yml 配置变更

### 4.1 全局变量说明

```yaml
vars:
  # ===== 雪花ID相关 =====
  snowflake_machine_id: 1
  # 机器/节点标识符 (0-1023)
  # 用于分布式部署时区分不同节点生成的ID
  # 单机部署保持默认值1即可

  snowflake_epoch: 1704067200000
  # 雪花ID时间戳起始点 (毫秒)
  # 2024-01-01 00:00:00 UTC 的Unix时间戳
  # 不建议修改，修改后已生成的ID将无法正确解析

  # ===== 增量控制相关 =====
  incremental_lookback_minutes: 5
  # 通用增量回溯窗口（分钟）
  # 用于处理边界时间附近的数据，防止因时钟偏差或事务延迟导致数据遗漏
  # 适用于 ERP/MES/LIMS/QMS/PV 系统

  high_frequency_lookback_minutes: 2
  # SCADA系统专用回溯窗口（分钟）
  # SCADA数据实时性高，使用更短的回溯窗口以减少重复处理
```

| 变量名 | 默认值 | 作用 | 修改建议 |
|--------|--------|------|----------|
| `snowflake_machine_id` | 1 | 分布式环境中的节点ID | 多节点部署时每个节点设置不同值 |
| `snowflake_epoch` | 1704067200000 | 雪花ID时间基准点 | **不建议修改** |
| `incremental_lookback_minutes` | 5 | 通用增量回溯窗口 | 根据数据延迟情况调整 |
| `high_frequency_lookback_minutes` | 2 | SCADA专用回溯窗口 | 根据采集频率调整 |

### 4.2 完整配置示例

```yaml
# 新增全局变量
vars:
  snowflake_machine_id: 1
  snowflake_epoch: 1704067200000
  incremental_lookback_minutes: 5
  high_frequency_lookback_minutes: 2

# 新增运行钩子
on-run-start:
  - \"{{ create_snowflake_function() }}\"

# Staging层配置
models:
  qrs:
    staging:
      +materialized: incremental
      +incremental_strategy: merge
      +on_schema_change: append_new_columns

      # 每个模型的 unique_key（见下方完整列表）
      stg_purchase_order:
        +unique_key: purchase_order_number
      # ... 其他44个模型配置

    # Business层事实表配置
    business:
      fct_purchase_orders:
        +materialized: incremental
        +unique_key: purchase_order_detail_id
        +incremental_strategy: merge
      # ... 其他38个事实表配置

      # 维度表保持 view
      dim_warehouses:
        +materialized: view
      # ... 其他9个维度表
```

---

## 五、需要修改的文件清单

### 新建文件 (2个)
| 文件路径 | 说明 |
|---------|------|
| `qrs/macros/snowflake/create_snowflake_function.sql` | PostgreSQL雪花ID函数 |
| `qrs/macros/snowflake/generate_snowflake_id.sql` | dbt雪花ID宏 |

### 修改文件 (83个)
| 类型 | 数量 | 修改内容 |
|------|------|---------|
| `dbt_project.yml` | 1 | 全局变量、on-run-start、物化配置 |
| Staging模型 (`stg_*.sql`) | 44 | 添加snowflake_id、is_incremental()过滤 |
| 事实表 (`fct_*.sql`) | 38 | 添加snowflake_id、incremental配置 |

---

## 六、实施步骤

### Phase 1: 基础设施 (Day 1)
1. 创建 `macros/snowflake/` 目录和两个宏文件
2. 更新 `dbt_project.yml` 添加变量和钩子
3. 运行 `dbt run-operation create_snowflake_function` 验证

### Phase 2: Staging层试点 (Day 2-3)
1. 改造3个代表性模型:
   - `stg_purchase_order` (有update_date)
   - `stg_deviation` (只有create_date)
   - `stg_equipment_data` (SCADA append)
2. 首次全量运行: `dbt run --select stg_purchase_order --full-refresh`
3. 验证增量运行

### Phase 3: Staging层批量改造 (Day 4-5)
- 批量修改剩余41个staging模型
- 更新对应的schema.yml测试文件

### Phase 4: Business层改造 (Day 6-8)
1. 改造3个代表性事实表:
   - `fct_purchase_orders`
   - `fct_inspection_results`
   - `fct_equipment_monitoring`
2. 批量修改剩余35个事实表

### Phase 5: 测试验证 (Day 9-10)
1. 运行所有测试: `dbt test`
2. 对比全量与增量结果一致性
3. 性能基准测试

---

## 七、验证方案

### 7.1 雪花ID验证
```bash
# 测试函数
dbt run-operation create_snowflake_function
psql -c \"SELECT generate_snowflake_id(1) as id;\"

# 验证唯一性
psql -c \"SELECT snowflake_id, count(*) FROM stg_purchase_order GROUP BY 1 HAVING count(*) > 1;\"
```

### 7.2 增量逻辑验证
```bash
# 首次全量
dbt run --select stg_purchase_order --full-refresh
dbt run --select fct_purchase_orders --full-refresh

# 模拟新数据后增量运行
dbt run --select stg_purchase_order
dbt run --select fct_purchase_orders

# 对比行数
psql -c \"SELECT count(*) FROM stg_purchase_order;\"
```

### 7.3 完整测试
```bash
dbt test --select tag:staging
dbt test --select tag:business_model
dbt build --full-refresh  # 最终全量验证
```

---

## 八、关键文件列表

| 文件 | 操作 | 优先级 |
|------|------|--------|
| `qrs/dbt_project.yml` | 修改 | P0 |
| `qrs/macros/snowflake/create_snowflake_function.sql` | 新建 | P0 |
| `qrs/macros/snowflake/generate_snowflake_id.sql` | 新建 | P0 |
| `qrs/models/staging/stg_purchase_order.sql` | 修改 | P1 |
| `qrs/models/staging/stg_equipment_data.sql` | 修改 | P1 |
| `qrs/models/business/fct_purchase_orders.sql` | 修改 | P1 |
| `qrs/models/business/fct_inspection_results.sql` | 修改 | P1 |

---

## 九、注意事项

1. **GxP合规**: 增量更新使用merge策略，不删除历史数据
2. **回溯窗口**: 默认24小时，处理late-arriving facts
3. **首次运行**: 必须使用 `--full-refresh` 初始化表结构
4. **维度表**: 保持view确保实时性，不转换为incremental
