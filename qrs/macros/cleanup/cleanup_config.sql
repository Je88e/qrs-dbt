{% macro get_cleanup_config() %}
{#
    清洗配置中心 - 定义所有需要清洗的snapshot与源表映射关系

    配置字段说明:
        snapshot_name: snapshot模型名
        source_schema: 源表所在schema
        source_table: 源表名
        primary_key: 主键字段
        enabled: 是否启用清洗
        retention_days: 删除标记保留天数 (超过此天数才执行清洗)
        priority: 清洗优先级 (1最高)
#}

{% set cleanup_configs = [
    {
        'snapshot_name': 'snap_material_receipts',
        'source_schema': 'public',
        'source_table': 'stg_material_receipt',
        'primary_key': 'receipt_id',
        'enabled': true,
        'retention_days': 30,
        'priority': 1
    },
    {
        'snapshot_name': 'snap_purchase_orders',
        'source_schema': 'public',
        'source_table': 'stg_purchase_order',
        'primary_key': 'purchase_order_number',
        'enabled': true,
        'retention_days': 30,
        'priority': 1
    },
    {
        'snapshot_name': 'snap_inspection_requests',
        'source_schema': 'public',
        'source_table': 'stg_inspection_request',
        'primary_key': 'request_id',
        'enabled': true,
        'retention_days': 60,
        'priority': 2
    },
    {
        'snapshot_name': 'snap_inspection_tasks',
        'source_schema': 'public',
        'source_table': 'stg_inspection_task',
        'primary_key': 'task_id',
        'enabled': true,
        'retention_days': 60,
        'priority': 2
    },
    {
        'snapshot_name': 'snap_change_controls',
        'source_schema': 'public',
        'source_table': 'stg_change_control',
        'primary_key': 'change_id',
        'enabled': true,
        'retention_days': 90,
        'priority': 3
    },
    {
        'snapshot_name': 'snap_deviations',
        'source_schema': 'public',
        'source_table': 'stg_deviation',
        'primary_key': 'deviation_id',
        'enabled': true,
        'retention_days': 90,
        'priority': 3
    },
    {
        'snapshot_name': 'snap_capas',
        'source_schema': 'public',
        'source_table': 'stg_capa',
        'primary_key': 'capa_id',
        'enabled': true,
        'retention_days': 90,
        'priority': 3
    }
] %}

{{ return(cleanup_configs) }}

{% endmacro %}
