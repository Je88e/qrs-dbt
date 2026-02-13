基于您提供的 dbt 项目环境及文档（特别是 `docs/audit/dbt Snapshot 功能深度解析:核心应用场景与实战价值.md`），结合业界最佳实践，为您详细阐述配置 Snapshot 以实现 SCD Type 2 的最佳实践。

### 1. 架构层级选择：Snapshot 应用位置

关于 Snapshot 应该构建在 Raw/Source 层、Staging 层还是 Business 层，这是一个核心的架构决策。

**推荐方案：应用在 Staging 层（清洗后的源数据）**

虽然理论上 Snapshot 越接近 Raw 层越好，但在实际工程中，构建在 **Staging 层**（即对 Source 进行轻量级清洗、重命名后的层级）通常是最佳平衡点。

| 层级 | 优点 | 缺点 | 场景分析 |
| :--- | :--- | :--- | :--- |
| **Raw / Source** | **数据保真度最高**。不受下游转换逻辑变更的影响，确保捕捉到源系统的最原始状态。 | **易用性差**。字段名可能晦涩（如 `COL_001`），数据类型可能不匹配。一旦源系统变更（Schema Drift），Snapshot 表结构也需立刻变更。 | 适用于源系统非常稳定且规范，或者你需要法律级别的“原始数据证据”的场景。 |
| **Staging** (推荐) | **解耦与易用性平衡**。你可以在 Staging 层统一字段命名（snake_case）、转换数据类型、处理 NULL 值。Snapshot 存储的是“标准化的历史”。 | **转换逻辑耦合**。如果 Staging 层的计算逻辑发生重大变化（不仅是重命名），可能需要重新构建 Snapshot，导致历史丢失。 | **当前项目采用此方案**（如 `snap_purchase_orders` 引用 `stg_purchase_order`）。这是大多数 dbt 项目的最佳实践，因为它让历史数据对下游分析更友好。 |
| **Business / Mart** | 业务逻辑已固化，直接存储业务结果的历史。 | **极度脆弱**。业务逻辑频繁变更（如改变毛利计算公式），会导致 Snapshot 记录“错误的业务历史”，且难以回溯修复。 | 仅在极少数需要追踪“复杂计算指标的历史变化”时使用，一般不建议作为 SCD Type 2 的主要来源。 |

**血缘依赖管理建议**：
确保 Snapshot 仅依赖于轻量级的 Staging 模型（主要做 casting 和 renaming），**避免**在 Snapshot 上游进行复杂的 JOIN 或聚合操作，以保持 Snapshot 的稳定性和纯粹性。

---

### 2. 配置策略：Strategy 与核心参数

#### Strategy 选择决策

*   **首选 `timestamp`**：
    *   **适用场景**：源表有可靠的 `updated_at`、`last_modified` 或 `etl_loaded_at` 字段。
    *   **优势**：性能极佳（仅对比时间戳字段），自动处理列的增加（Schema Drift）。
    *   **当前项目实践**：文档显示项目统一使用了 `timestamp` 策略，这是一个很好的选择。

*   **备选 `check`**：
    *   **适用场景**：源表没有更新时间戳，或者时间戳不可靠（例如只在创建时写入，更新时不更新）。
    *   **配置**：`check_cols: ['status', 'amount']` 或 `check_cols: 'all'`。
    *   **劣势**：性能较差（需要计算哈希值对比）；如果使用 `check_cols: 'all'`，当源表增加无关紧要的列（如备注字段）时也会触发新版本记录，导致存储膨胀。

#### 配置代码示例

结合您项目中的 `qrs/snapshots/erp/snap_purchase_orders.sql`，以下是一个标准化的最佳实践配置：

```sql
{% snapshot snap_purchase_orders %}

{{
    config(
        target_schema='snapshots',
        unique_key='purchase_order_number', -- 业务主键
        
        -- 策略配置
        strategy='timestamp',
        updated_at='update_date', -- 源表中的更新时间戳
        -- 如果使用 check 策略：
        -- strategy='check',
        -- check_cols=['order_status', 'total_amount'], 
        
        -- 核心最佳实践配置
        invalidate_hard_deletes=True, -- (新版dbt推荐) 或 hard_deletes='new_record'，追踪源表物理删除的记录
        dbt_valid_to_current="'9999-12-31'::date", -- 将当前记录的失效时间设为远未来，而非 NULL，便于索引和查询
        
        -- 自定义元数据列名（建议统一，方便下游引用）
        snapshot_meta_column_names={
            'dbt_valid_from': 'valid_from',
            'dbt_valid_to': 'valid_to',
            'dbt_scd_id': 'snapshot_id',
            'dbt_updated_at': 'last_updated_at',
            'dbt_is_deleted': 'is_deleted'
        }
    )
}}

select * from {{ ref('stg_purchase_order') }}

{% endsnapshot %}
```

---

### 3. 下游引用与维护

#### 下游如何正确引用（还原特定时间点业务状态）

下游 Business/Mart 层不应直接使用 Snapshot 的原始表，通常需要通过 View 或 CTE 封装逻辑。

**场景 A：获取当前最新状态**
```sql
select *
from {{ ref('snap_purchase_orders') }}
where valid_to = '9999-12-31'::date
-- 只有配置了 invalidate_hard_deletes/hard_deletes 时才需要过滤删除标记
and is_deleted = 'False' 
```

**场景 B：还原特定时间点（Point-in-Time）的状态**
例如，分析“2023年6月1日”时的订单状态：
```sql
{% set analysis_date = "'2023-06-01'::date" %}

select *
from {{ ref('snap_purchase_orders') }}
where valid_from <= {{ analysis_date }}
  and (valid_to > {{ analysis_date }} or valid_to is null) -- 兼容 valid_to 为 null 的情况
```

**场景 C：还原事实表发生时对应的维度状态（关键）**
当连接 Fact 表（如 `fct_sales`）和 Snapshot 维度表时，必须使用范围连接：
```sql
select 
    f.order_id,
    f.order_date,
    s.order_status as status_at_time_of_sale
from {{ ref('fct_sales') }} f
left join {{ ref('snap_purchase_orders') }} s
    on f.order_id = s.purchase_order_number
    and f.order_date >= s.valid_from
    and (f.order_date < s.valid_to or s.valid_to is null)
```

#### Schema Drift（表结构变更）处理

*   **新增列**：dbt Snapshot（特别是 `timestamp` 策略）非常智能。如果 Source 新增了一列，dbt 会自动在 Snapshot 表中 Alter Table 添加该列，并开始追踪。
*   **删除/重命名列**：这是风险点。如果 Source 删除了列，Snapshot 表中该列会保留但后续数据为 NULL。如果重命名，dbt 会视作“删除旧列 + 新增新列”，导致历史数据断裂。
    *   **建议**：在 Staging 层做一层缓冲。如果 Source 字段改名，在 Staging 层的 SQL 中使用 `AS` 别名将其映射回旧名称，保持 Snapshot 结构稳定。

#### 性能优化建议（应对数据量膨胀）

随着时间推移，SCD Type 2 表会变得非常大。

1.  **索引优化**：
    您项目中的 `create_snapshot_indexes` 宏是一个很好的实践。建议至少建立以下索引：
    *   **(Unique Key, Valid To)**: 加速查询当前状态。
    *   **(Unique Key, Valid From)**: 加速历史回溯。
    *   **(Valid From, Valid To)**: 加速时间范围分析。

2.  **分区（Partitioning）**：
    对于亿级数据量的 Snapshot 表，建议在数据仓库层面（如 Snowflake, BigQuery, Postgres）按 `valid_from` 进行分区（Range Partitioning）。这能让查询特定年份历史数据时大幅减少扫描量。

3.  **下游增量构建**：
    下游的模型引用 Snapshot 时，务必使用 **Incremental 模型**。因为 Snapshot 表本身是全量累积的，如果下游每次都全量扫描 Snapshot 计算，成本会爆炸。
    ```sql
    {{ config(materialized='incremental') }}
    
    select ...
    from {{ ref('snap_purchase_orders') }}
    where valid_from > (select max(max_valid_from) from {{ this }}) -- 仅处理新产生的快照记录
    ```