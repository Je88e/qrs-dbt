with invalid_rows as (
    select
        batch_process_parameter_id,
        work_order_number,
        operation_id,
        param_name,
        total_points,
        out_of_spec_points,
        oos_rate
    from {{ ref('fct_batch_process_parameters') }}
    where
        total_points is null
        or out_of_spec_points is null
        or total_points < 0
        or out_of_spec_points < 0
        or out_of_spec_points > total_points
        or (oos_rate is not null and (oos_rate < 0 or oos_rate > 1))
)

select * from invalid_rows
