{% set collision_timezone = var('group16_collision_timestamp_timezone', 'UNCONFIRMED') %}
{% set request_timezone = var('group16_311_timestamp_timezone', 'UNCONFIRMED') %}

with expected as (
    select 'collisions' as model_name, count(*) as row_count
    from {{ source('group16_raw', 'source_nyc_mv_collisions') }}
    where date({{ group16_local_datetime('crash_date', collision_timezone, 'group16_collision_timestamp_timezone') }})
        between date '2021-01-01' and date '2026-06-30'
    union all
    select 'requests', count(*)
    from {{ source('group16_raw', 'source_nyc_311_streetlight_signal') }}
    where date({{ group16_local_datetime('created_date', request_timezone, 'group16_311_timestamp_timezone') }})
        between date '2021-01-01' and date '2026-06-30'
      and upper(regexp_replace(trim(complaint_type), r'\s+', ' '))
        in ('STREET LIGHT CONDITION', 'TRAFFIC SIGNAL CONDITION')
),
actual as (
    select 'collisions' as model_name, count(*) as row_count from {{ ref('stg_nyc_collisions') }}
    union all
    select 'requests', count(*) from {{ ref('stg_nyc_311_requests') }}
)
select e.model_name, e.row_count as expected_rows, a.row_count as staged_rows
from expected e
join actual a using (model_name)
where e.row_count != a.row_count
