{{
    config(
        materialized='view',
        tags=['staging', 'qms', 'quality']
    )
}}

/*
    Model: stg_capa
    Description: QMS CAPA主数据原始数据清洗层 - Staging层
    Source: QMS系统CAPA主表
    Grain: 每行代表一条CAPA记录
*/

with source_data as (
    select * from {{ source('qms_raw', 'qms_capa') }}
),

final as (
    select
        capa_id,
        capa_code,
        capa_title,
        capa_type,
        source_type,
        source_id,
        description as capa_description,
        root_cause_analysis,
        corrective_action,
        preventive_action,
        responsible,
        planned_completion,
        actual_completion,
        status as capa_status,
        effectiveness_check,
        effectiveness_date,
        creator,
        approver,
        create_date
    from source_data
)

select * from final