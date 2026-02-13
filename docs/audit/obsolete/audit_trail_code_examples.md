# 审计跟踪系统代码示例

本文档提供审计跟踪系统的完整代码示例，可直接用于实施。

---

## 1. 快照配置示例

### 示例 1: 采购订单快照（完整配置）

**文件**: `qrs/snapshots/erp/snap_purchase_orders.yml`

```yaml
version: 2

snapshots:
  - name: snap_purchase_orders
    description: |
      采购订单状态变更快照 - 追踪订单全生命周期
      
      业务场景:
      - 订单审批流程追踪
      - 订单处理时长分析
      - 合规审计支持
      
    relation: ref('stg_purchase_order')
    
    config:
      schema: snapshots
      unique_key: purchase_order_number
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
      
      tags: ['snapshot', 'erp', 'audit']
      
      post-hook:
        - "CREATE INDEX IF NOT EXISTS idx_{{ this.name }}_current 
           ON {{ this }} (purchase_order_number) 
           WHERE valid_to = '9999-12-31' AND is_deleted = 'False'"
        - "ANALYZE {{ this }}"
    
    columns:
      - name: purchase_order_number
        data_tests:
          - not_null
          - dbt_utils.unique_combination_of_columns:
              combination_of_columns:
                - purchase_order_number
                - valid_from
      
      - name: order_status
        data_tests:
          - not_null
          - accepted_values:
              values: ['待审批', '已审批', '进行中', '已完成', '已取消']
      
      - name: valid_from
        data_tests:
          - not_null
      
      - name: valid_to
        data_tests:
          - not_null
```

### 示例 2: 检验请求快照（高频更新）

**文件**: `qrs/snapshots/lims/snap_inspection_requests.yml`

```yaml
version: 2

snapshots:
  - name: snap_inspection_requests
    description: 检验请求状态快照 - 高频更新（每 4 小时）
    
    relation: ref('stg_inspection_request')
    
    config:
      schema: snapshots
      unique_key: request_id
      strategy: timestamp
      updated_at: update_date
      hard_deletes: new_record
      dbt_valid_to_current: '9999-12-31'
      tags: ['snapshot', 'lims', 'audit', 'high_frequency']
```

---

## 2. 审计宏示例

### 示例 1: 数据标准化宏

**文件**: `qrs/macros/audit/standardize_for_audit.sql`

```sql
{% macro standardize_for_audit(column_name, data_type) %}

/*
    宏: standardize_for_audit
    描述: 标准化列值以便审计对比
    
    参数:
    - column_name: 列名
    - data_type: 数据类型
      - 'timestamp': 时间戳（转 UTC）
      - 'numeric': 数值（保留 2 位小数）
      - 'string': 字符串（trim + lower）
      - 'boolean': 布尔值（标准化）
    
    示例:
    {{ standardize_for_audit('create_date', 'timestamp') }}
    {{ standardize_for_audit('total_amount', 'numeric') }}
*/

{% if data_type == 'timestamp' %}
    {{ column_name }}::timestamp at time zone 'UTC'
    
{% elif data_type == 'numeric' %}
    round({{ column_name }}::numeric, 2)
    
{% elif data_type == 'string' %}
    trim(lower({{ column_name }}::text))
    
{% elif data_type == 'boolean' %}
    case
        when {{ column_name }}::text in ('true', 't', '1', 'yes', 'y', 'True', 'TRUE') then true
        when {{ column_name }}::text in ('false', 'f', '0', 'no', 'n', 'False', 'FALSE') then false
        else null
    end
    
{% else %}
    {{ column_name }}
    
{% endif %}

{% endmacro %}
```

### 示例 2: 获取当前快照记录宏

**文件**: `qrs/macros/audit/get_current_snapshot.sql`

```sql
{% macro get_current_snapshot(snapshot_name, as_of_date=None) %}

/*
    宏: get_current_snapshot
    描述: 获取快照表的当前有效记录或指定时间点的记录
    
    参数:
    - snapshot_name: 快照表名称
    - as_of_date: 可选，指定时间点（格式: 'YYYY-MM-DD'）
    
    返回: 当前有效且未删除的记录
    
    示例:
    -- 获取当前记录
    select * from {{ get_current_snapshot('snap_purchase_orders') }}
    
    -- 获取 2024-01-01 时的记录
    select * from {{ get_current_snapshot('snap_purchase_orders', '2024-01-01') }}
*/

(
    select *
    from {{ ref(snapshot_name) }}
    where 
        {% if as_of_date %}
        valid_from <= '{{ as_of_date }}'::date
        and (valid_to > '{{ as_of_date }}'::date or valid_to = '9999-12-31')
        {% else %}
        valid_to = '9999-12-31'
        {% endif %}
        and is_deleted = 'False'
)

{% endmacro %}
```

---

## 3. 审计分析示例

### 示例 1: 行级审计（采购订单）

**文件**: `qrs/analyses/audit/row_audit/audit_purchase_orders_rows.sql`

```sql
/*
    审计模型: audit_purchase_orders_rows
    描述: 对比旧系统与 dbt 模型的采购订单数据
    
    审计范围: 2024-01-01 至今
    预期匹配率: >= 99.5%
*/

{# 定义旧系统查询 #}
{% set old_system_query %}
select
    po_number as purchase_order_number,
    supplier_id,
    po_type as order_type,
    po_status as order_status,
    {{ standardize_for_audit('order_date', 'timestamp') }} as order_date,
    {{ standardize_for_audit('total_amount', 'numeric') }} as total_amount,
    {{ standardize_for_audit('currency', 'string') }} as currency
from legacy_schema.purchase_orders
where order_date >= '2024-01-01'
{% endset %}

{# 定义新系统查询 #}
{% set new_system_query %}
select
    purchase_order_number,
    supplier_id,
    order_type,
    order_status,
    {{ standardize_for_audit('order_date', 'timestamp') }} as order_date,
    {{ standardize_for_audit('total_amount', 'numeric') }} as total_amount,
    {{ standardize_for_audit('currency', 'string') }} as currency
from {{ ref('fct_purchase_orders') }}
where order_date >= '2024-01-01'
{% endset %}

{# 执行行级对比 #}
{{ audit_helper.compare_queries(
    a_query=old_system_query,
    b_query=new_system_query,
    primary_key="purchase_order_number",
    summarize=true
) }}
```

