{% macro create_snapshot_indexes() %}

{#
    宏: create_snapshot_indexes
    描述: 为所有快照表创建性能优化索引
    
    使用方法:
    dbt run-operation create_snapshot_indexes
    
    索引策略:
    1. 当前记录部分索引（最常用查询）
    2. 时间范围复合索引（历史查询）
    3. 主键 + 时间复合索引（点查询）
    4. 删除记录部分索引（审计查询）
#}

{% set snapshots = [
    {'name': 'snap_purchase_orders', 'key': 'purchase_order_number'},
    {'name': 'snap_material_receipts', 'key': 'receipt_id'},
    {'name': 'snap_inspection_requests', 'key': 'request_id'},
    {'name': 'snap_inspection_tasks', 'key': 'task_id'},
    {'name': 'snap_change_controls', 'key': 'change_id'},
    {'name': 'snap_deviations', 'key': 'deviation_id'},
    {'name': 'snap_capas', 'key': 'capa_id'}
] %}

{# 使用 snapshots schema（与快照配置中的 target_schema 一致）#}
{% set schema = 'snapshots' %}

{% for snapshot in snapshots %}

{% set table = snapshot.name %}
{% set key = snapshot.key %}

{% do log("============================================", info=true) %}
{% do log("创建索引: " ~ table, info=true) %}
{% do log("============================================", info=true) %}

-- 索引 1: 当前记录查询优化（部分索引，最高优先级）
{% set sql_1 %}
CREATE INDEX IF NOT EXISTS idx_{{ table }}_current
ON {{ schema }}.{{ table }} ({{ key }})
WHERE valid_to = '9999-12-31' AND is_deleted = 0;
{% endset %}

{% do run_query(sql_1) %}
{% do log("✓ idx_" ~ table ~ "_current 创建成功", info=true) %}

-- 索引 2: 时间范围查询优化（历史分析）
{% set sql_2 %}
CREATE INDEX IF NOT EXISTS idx_{{ table }}_valid_range
ON {{ schema }}.{{ table }} (valid_from DESC, valid_to DESC);
{% endset %}

{% do run_query(sql_2) %}
{% do log("✓ idx_" ~ table ~ "_valid_range 创建成功", info=true) %}

-- 索引 3: 主键 + 时间复合索引（点查询优化）
{% set sql_3 %}
CREATE INDEX IF NOT EXISTS idx_{{ table }}_key_time
ON {{ schema }}.{{ table }} ({{ key }}, valid_from DESC);
{% endset %}

{% do run_query(sql_3) %}
{% do log("✓ idx_" ~ table ~ "_key_time 创建成功", info=true) %}

-- 索引 4: 删除记录查询（审计需求）
{% set sql_4 %}
CREATE INDEX IF NOT EXISTS idx_{{ table }}_deleted
ON {{ schema }}.{{ table }} ({{ key }}, valid_from)
WHERE is_deleted = 1;
{% endset %}

{% do run_query(sql_4) %}
{% do log("✓ idx_" ~ table ~ "_deleted 创建成功", info=true) %}

-- 更新表统计信息
{% set sql_analyze %}
ANALYZE {{ schema }}.{{ table }};
{% endset %}

{% do run_query(sql_analyze) %}
{% do log("✓ 统计信息已更新", info=true) %}
{% do log("", info=true) %}

{% endfor %}

{% do log("所有快照索引创建完成！", info=true) %}

{% endmacro %}

