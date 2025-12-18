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

renamed as (
    select
        capa_id,
        capa_number,
        capa_type,
        capa_status,
        source_reference,
        capa_description,
        responsible_person,
        due_date,
        completion_date,
        effectiveness_check,
        effectiveness_check_date,
        created_at,
        updated_at
    from source_data
)

select * from renamed

