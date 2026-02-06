{% macro create_snowflake_function() %}

CREATE SEQUENCE IF NOT EXISTS snowflake_seq
    MINVALUE 0 MAXVALUE 4095 CYCLE;

CREATE OR REPLACE FUNCTION generate_snowflake_id(
    machine_id INT DEFAULT {{ var('snowflake_machine_id', 1) }}
) RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE
    epoch_ms BIGINT := 1704067200000;  -- 2024-01-01 UTC
    current_ms BIGINT;
    seq_id INT;
BEGIN
    current_ms := (EXTRACT(EPOCH FROM clock_timestamp()) * 1000)::BIGINT - epoch_ms;
    seq_id := nextval('snowflake_seq')::INT;
    -- 结构: 41位时间戳 + 10位机器ID + 12位序列号
    RETURN (current_ms << 22) | ((machine_id & 1023) << 12) | (seq_id & 4095);
END;
$$;

{% endmacro %}
