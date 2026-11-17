{{ config(severity='warn') }}

-- These rows cannot be assigned to an analysis period and are excluded by staging.
select 'collisions' as source_name, count(*) as missing_date_rows
from {{ source('group16_raw', 'source_nyc_mv_collisions') }}
where crash_date is null
having count(*) > 0
union all
select 'requests', count(*)
from {{ source('group16_raw', 'source_nyc_311_streetlight_signal') }}
where created_date is null
  and upper(regexp_replace(trim(complaint_type), r'\s+', ' '))
    in ('STREET LIGHT CONDITION', 'TRAFFIC SIGNAL CONDITION')
having count(*) > 0
