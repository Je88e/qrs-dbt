{% macro cleanup_post_hook(snapshot_name, source_schema, source_table, primary_key, auto_execute=false) %}
{#
    用于snapshot模型的post-hook
    在snapshot刷新后自动检测并处理删除记录

    使用方式 (在snapshot配置中):
        post_hook="{{ cleanup_post_hook(
            snapshot_name='snap_material_receipts',
            source_schema='raw',
            source_table='erp_material_receipts',
            primary_key='receipt_id',
            auto_execute=false
        ) }}"

    参数:
        auto_execute: 是否自动执行删除 (默认false，仅记录)
                      生产环境建议设为false，通过定时任务手动触发
#}

-- Post-hook: 记录删除候选到暂存表
insert into audit.cleanup_pending_queue (
    snapshot_name,
    source_schema,
    source_table,
    primary_key_field,
    record_id,
    detected_at,
    auto_execute
)
select
    '{{ snapshot_name }}',
    '{{ source_schema }}',
    '{{ source_table }}',
    '{{ primary_key }}',
    {{ primary_key }}::varchar,
    current_timestamp,
    {{ auto_execute }}
from {{ this }}
where dbt_is_deleted = 'True'
  and dbt_valid_to is null
on conflict (snapshot_name, record_id) do update
set detected_at = current_timestamp;

{% if auto_execute %}
-- 警告: auto_execute=true 将立即删除源表数据
-- 仅在测试环境使用此选项
{% endif %}

{% endmacro %}


{% macro create_cleanup_pending_queue() %}
{#
    创建清洗待处理队列表
    运行: dbt run-operation create_cleanup_pending_queue
#}

{% set sql %}
    create schema if not exists audit;

    create table if not exists audit.cleanup_pending_queue (
        id serial primary key,
        snapshot_name varchar(255) not null,
        source_schema varchar(255) not null,
        source_table varchar(255) not null,
        primary_key_field varchar(255) not null,
        record_id varchar(255) not null,
        detected_at timestamp default current_timestamp,
        processed_at timestamp,
        auto_execute boolean default false,
        status varchar(50) default 'pending',
        constraint uq_cleanup_queue unique (snapshot_name, record_id)
    );

    create index if not exists idx_cleanup_queue_status
        on audit.cleanup_pending_queue(status, detected_at);

    comment on table audit.cleanup_pending_queue is
        '清洗待处理队列 - 由snapshot post-hook自动填充';
{% endset %}

{% do run_query(sql) %}
{{ log("✅ 清洗待处理队列表已创建", info=true) }}

{% endmacro %}
