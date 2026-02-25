with failures as (
    select
        'stg_capa' as model_name,
        'row_count_gt_0' as test_name,
        1 as failing_count
    where (select count(*) from {{ ref('stg_capa') }}) = 0

    union all

    select
        'stg_capa' as model_name,
        'key_fields_not_null' as test_name,
        count(*) as failing_count
    from {{ ref('stg_capa') }}
    where source_event_id is null
       or source_system is null
       or event_type is null

    union all

    select
        'stg_deviation' as model_name,
        'row_count_gt_0' as test_name,
        1 as failing_count
    where (select count(*) from {{ ref('stg_deviation') }}) = 0

    union all

    select
        'stg_deviation' as model_name,
        'key_fields_not_null' as test_name,
        count(*) as failing_count
    from {{ ref('stg_deviation') }}
    where source_event_id is null
       or source_system is null
       or event_type is null

    union all

    select
        'stg_change_control' as model_name,
        'row_count_gt_0' as test_name,
        1 as failing_count
    where (select count(*) from {{ ref('stg_change_control') }}) = 0

    union all

    select
        'stg_change_control' as model_name,
        'key_fields_not_null' as test_name,
        count(*) as failing_count
    from {{ ref('stg_change_control') }}
    where source_event_id is null
       or source_system is null
       or event_type is null

    union all

    select
        'stg_complaint' as model_name,
        'row_count_gt_0' as test_name,
        1 as failing_count
    where (select count(*) from {{ ref('stg_complaint') }}) = 0

    union all

    select
        'stg_complaint' as model_name,
        'key_fields_not_null' as test_name,
        count(*) as failing_count
    from {{ ref('stg_complaint') }}
    where source_event_id is null
       or source_system is null
       or event_type is null

    union all

    select
        'stg_product_recall' as model_name,
        'row_count_gt_0' as test_name,
        1 as failing_count
    where (select count(*) from {{ ref('stg_product_recall') }}) = 0

    union all

    select
        'stg_product_recall' as model_name,
        'key_fields_not_null' as test_name,
        count(*) as failing_count
    from {{ ref('stg_product_recall') }}
    where source_event_id is null
       or source_system is null
       or event_type is null
)

select *
from failures
where failing_count > 0
