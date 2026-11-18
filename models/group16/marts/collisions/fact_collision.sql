{{ config(materialized='table') }}

-- Left joins retain each staged collision. Missing dimension matches fail
-- not-null tests; duplicate dimension members fail uniqueness/count tests.
select
    s.collision_id,
    d.date_key as crash_date_key,
    t.time_key as crash_time_key,
    l.location_key,
    v.severity_key,
    s.collision_count,
    s.number_of_persons_injured,
    s.number_of_persons_killed,
    s.number_of_pedestrians_injured,
    s.number_of_pedestrians_killed,
    s.number_of_cyclist_injured,
    s.number_of_cyclist_killed,
    s.number_of_motorist_injured,
    s.number_of_motorist_killed,
    s.loaded_at_utc
from {{ ref('stg_nyc_collisions') }} as s
left join {{ ref('dim_date') }} as d
    on s.crash_date_key = d.date_key
left join {{ ref('dim_time') }} as t
    on s.crash_time_key = t.time_key
left join {{ ref('dim_location') }} as l
    on s.borough = l.borough and s.zip_code = l.zip_code
left join {{ ref('dim_crash_severity') }} as v
    on s.severity_key = v.severity_key
