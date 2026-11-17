{{ config(materialized='table', tags=['group16_staging']) }}
{% set timestamp_timezone = var('group16_collision_timestamp_timezone', 'UNCONFIRMED') %}

{% set counts = [
    'number_of_persons_injured', 'number_of_persons_killed',
    'number_of_pedestrians_injured', 'number_of_pedestrians_killed',
    'number_of_cyclist_injured', 'number_of_cyclist_killed',
    'number_of_motorist_injured', 'number_of_motorist_killed'
] %}

with normalized as (
    select
        collision_id,
        crash_date as raw_crash_timestamp,
        date({{ group16_local_datetime('crash_date', timestamp_timezone, 'group16_collision_timestamp_timezone') }}) as crash_date,
        nullif(trim(crash_time), '') as raw_crash_time,
        coalesce(
            safe.parse_time('%H:%M', nullif(trim(crash_time), '')),
            safe.parse_time('%H:%M:%S', nullif(trim(crash_time), ''))
        ) as crash_time,
        {{ group16_borough('borough') }} as borough,
        {{ group16_zip('zip_code') }} as zip_code,
        {% for column in counts %}
        {% if column in ['number_of_persons_injured', 'number_of_persons_killed'] %}
        {{ group16_integer(column) }} as {{ column }},
        {% else %}
        -- The model specifies zero for missing subgroup counts; invalid text stays null.
        case when nullif(trim(cast({{ column }} as string)), '') is null then 0
             else {{ group16_integer(column) }} end as {{ column }},
        {% endif %}
        {% endfor %}
        (
            {% for column in counts %}
            {{ group16_invalid_count(column) }}{% if not loop.last %} or{% endif %}
            {% endfor %}
        ) as has_invalid_injury_count
    from {{ source('group16_raw', 'source_nyc_mv_collisions') }}
),

in_scope as (
    select *
    from normalized
    where crash_date >= date '2021-01-01'
      and crash_date < date '2026-07-01'
),

classified as (
    select *,
        case
            when number_of_persons_killed >= 1 then 4
            when number_of_persons_killed is null or number_of_persons_injured is null then 0
            when number_of_persons_killed = 0 and number_of_persons_injured >= 2 then 3
            when number_of_persons_killed = 0 and number_of_persons_injured = 1 then 2
            when number_of_persons_killed = 0 and number_of_persons_injured = 0 then 1
            else 0
        end as severity_key
    from in_scope
)

-- Keep duplicate IDs so uniqueness tests expose them; there is no reliable
-- source update/load timestamp with which to choose a latest record.
select
    collision_id,
    crash_date,
    crash_time,
    cast(format_date('%Y%m%d', crash_date) as int64) as crash_date_key,
    coalesce(extract(hour from crash_time) * 100 + extract(minute from crash_time), -1) as crash_time_key,
    borough,
    zip_code,
    severity_key,
    severity_key in (2, 3, 4) as is_injury_or_fatal,
    1 as collision_count,
    {% for column in counts %}
    {{ column }},
    {% endfor %}
    raw_crash_timestamp,
    raw_crash_time,
    has_invalid_injury_count,
    raw_crash_time is not null and crash_time is null as has_invalid_crash_time,
    current_timestamp() as staged_at_utc
from classified
