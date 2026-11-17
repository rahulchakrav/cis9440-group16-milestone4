-- Compare these two interpretations with the original source values or loader code.
-- These samples alone do not prove how the timestamps were encoded.
with collision_samples as (
    select 'collisions' as source_name, cast(collision_id as string) as source_id,
        crash_date as raw_timestamp,
        datetime(crash_date, 'UTC') as utc_clock,
        datetime(crash_date, 'America/New_York') as new_york_clock
    from {{ source('group16_raw', 'source_nyc_mv_collisions') }}
    where crash_date is not null
    order by collision_id
    limit 5
),
request_samples as (
    select 'requests' as source_name, unique_key as source_id,
        created_date as raw_timestamp,
        datetime(created_date, 'UTC') as utc_clock,
        datetime(created_date, 'America/New_York') as new_york_clock
    from {{ source('group16_raw', 'source_nyc_311_streetlight_signal') }}
    where created_date is not null
    order by unique_key
    limit 5
)
select * from collision_samples
union all
select * from request_samples
