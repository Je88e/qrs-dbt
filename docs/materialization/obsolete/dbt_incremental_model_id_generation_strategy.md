# dbt 增量模型中不可变 ID (Immutable ID) 的生成策略

## 背景说明

在构建 dbt 增量模型（Incremental Models）时，通常会为每条记录生成一个技术主键或代理键（Surrogate Key），例如使用 `generate_snowflake_id()` 生成的 `snowflake_id`。

当模型配置为 `incremental` 且使用 `merge` 策略时，如果这个 ID 列在每次运行时都重新生成（非确定性），会导致以下严重问题：
1. **重复数据插入**：即使配置了 `unique_key`（如业务主键 `event_id`），但如果 dbt 在处理逻辑中未能正确识别旧记录，可能会导致重复插入。
2. **ID 不稳定性**：对于已存在的记录，其 ID 会在每次运行时发生变化，破坏了数据仓库中维度的稳定性，影响下游依赖。

本文档提供了两种解决方案，确保在增量更新时，**已存在记录的 ID 保持不变，仅为真正的新插入记录生成新 ID**。

---

## 方案一：使用 COALESCE 保留现有 ID（推荐）

这是最通用且标准的解决方案，适用于所有支持增量模型的 dbt 版本。

### 核心逻辑
1. 在增量运行时，通过 `LEFT JOIN` 读取目标表（`{{ this }}`）中已存在的记录。
2. 使用 `COALESCE` 函数优先取用目标表中已存在的 ID。
3. 仅当目标表中不存在该记录（即新记录）时，才调用生成函数创建新 ID。

### 代码实现示例

```sql
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='event_id',  -- 业务主键
        on_schema_change='append_new_columns'
    )
}}

with source_data as (
    select * from {{ source('pv_raw', 'pv_adverse_event') }}
),

-- 1. 在增量模式下，获取目标表中已存在的 ID
{% if is_incremental() %}
existing_records as (
    select event_id, snowflake_id
    from {{ this }}
),
{% endif %}

final as (
    select
        -- 2. 关键逻辑：优先使用已存在的 ID，不存在则生成新 ID
        {% if is_incremental() -%}
        coalesce(existing.snowflake_id, {{ generate_snowflake_id() }}::text) as snowflake_id,
        {% else -%}
        {{ generate_snowflake_id() }}::text as snowflake_id,
        {% endif -%}
        
        source.event_id,
        -- ... 其他字段
        source.updated_at
    
    from source_data source
    
    -- 3. 关联现有记录
    {% if is_incremental() -%}
    left join existing_records existing
        on source.event_id = existing.event_id
    {% endif -%}
)

select * from final
{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

### 优缺点分析
*   **优点**：
    *   **通用性强**：不依赖特定数据库特性或 dbt 版本。
    *   **逻辑清晰**：显式地控制了 ID 的生成逻辑。
    *   **保留历史**：完美保留了记录首次创建时生成的 ID。
*   **缺点**：
    *   **性能开销**：在增量运行时需要额外的 `LEFT JOIN` 操作，对于超大数据集可能会增加处理时间。

---

## 方案二：使用 merge_exclude_columns 配置（需 dbt v1.5+）

如果你使用的是 dbt v1.5 或更高版本，利用 `merge_exclude_columns` 配置是一种更简洁的方法。

### 核心逻辑
告诉 dbt 在执行 `MERGE` 更新操作（当 `unique_key` 匹配时）时，**不要更新**指定的列（如 `snowflake_id`）。这样，即使 SQL 逻辑中生成了新 ID，更新操作也会忽略它，从而保留目标表中的旧值。

### 代码实现示例

```sql
{{
    config(
        materialized='incremental',
        incremental_strategy='merge',
        unique_key='event_id',
        
        -- 关键配置：在 merge 更新时排除 ID 列，保持原值不变
        merge_exclude_columns=['snowflake_id', 'created_at'],
        
        on_schema_change='append_new_columns'
    )
}}

with source_data as (
    select * from {{ source('pv_raw', 'pv_adverse_event') }}
),

final as (
    select
        -- 这里每次运行都会生成新 ID，但对于 UPDATE 操作，这个新值会被忽略
        {{ generate_snowflake_id() }}::text as snowflake_id,
        
        event_id,
        -- ... 其他字段
        current_timestamp as created_at, -- created_at 同样也不应该被更新
        updated_at
    from source_data
)

select * from final
{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

### 优缺点分析
*   **优点**：
    *   **代码简洁**：无需编写复杂的 JOIN 逻辑和 Jinja 模板代码。
    *   **维护方便**：通过配置管理，意图更直观。
*   **缺点**：
    *   **版本限制**：仅支持 dbt Core v1.5+ 及特定适配器（Postgres, Snowflake, BigQuery, Spark 等支持）。
    *   **隐式行为**：ID 生成逻辑隐含在配置中，不如方案一直接可见。

---

## 总结与建议

| 维度 | 方案一 (COALESCE + JOIN) | 方案二 (merge_exclude_columns) |
| :--- | :--- | :--- |
| **推荐度** | ⭐⭐⭐⭐⭐ (首选) | ⭐⭐⭐⭐ |
| **兼容性** | 所有版本 | dbt v1.5+ |
| **性能** | 中 (需 Join) | 高 (数据库原生处理) |
| **适用性** | 所有场景 | 仅限 merge 策略 |

**建议**：
除非你非常确定项目环境将长期锁定在 dbt v1.5+ 且使用支持该特性的数据库适配器，否则**建议优先使用方案一**。方案一虽然代码稍长，但它提供了最稳健、最透明的控制逻辑，不易受底层环境变化影响。
