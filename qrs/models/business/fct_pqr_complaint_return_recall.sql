{{
    config(
        materialized='view',
        tags=["business_model", "pqr", "events", "scope"]
    )
}}

with batch_universe as (
    select * from {{ ref('int_pqr__batch_universe') }}
),

complaints as (
    select * from {{ ref('fct_complaints') }}
),

customer_returns as (
    select * from {{ ref('fct_customer_returns') }}
),

product_recalls as (
    select * from {{ ref('fct_product_recalls') }}
),

recall_batches as (
    select
        recall_id,
        recall_code,
        product_id,
        trim(bn) as batch_number,
        recall_level,
        recall_reason,
        recall_date,
        recall_status,
        create_date
    from product_recalls r
    cross join lateral unnest(string_to_array(coalesce(r.batch_numbers, ''), ',')) as bn
    where coalesce(trim(bn), '') <> ''
),

unioned_events as (
    select
        'complaint'::text as event_type,
        complaint_id::text as event_id,
        complaint_code::text as event_code,
        product_id::text as product_id,
        batch_number::text as batch_number,
        complaint_date::date as event_date,
        complaint_status::text as event_status,
        null::numeric as event_quantity,
        create_date as create_date
    from complaints

    union all

    select
        'return'::text as event_type,
        return_id::text as event_id,
        return_code::text as event_code,
        product_id::text as product_id,
        batch_number::text as batch_number,
        return_date::date as event_date,
        return_status::text as event_status,
        return_quantity as event_quantity,
        create_date as create_date
    from customer_returns

    union all

    select
        'recall'::text as event_type,
        recall_id::text as event_id,
        recall_code::text as event_code,
        product_id::text as product_id,
        batch_number::text as batch_number,
        recall_date::date as event_date,
        recall_status::text as event_status,
        null::numeric as event_quantity,
        create_date as create_date
    from recall_batches
),

final as (
    select
        u.review_scope_id,
        u.version_no,
        e.event_type,
        e.event_id,
        e.event_code,
        e.product_id,
        e.batch_number,
        e.event_date,
        e.event_status,
        e.event_quantity,
        e.create_date
    from unioned_events e
    inner join batch_universe u
        on e.product_id = u.product_id
       and e.batch_number = u.batch_number
)

select * from final
