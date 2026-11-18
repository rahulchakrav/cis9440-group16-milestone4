{{ config(materialized='table', tags=['group16_staging']) }}
{% set timestamp_timezone = var('group16_311_timestamp_timezone', 'UNCONFIRMED') %}

with normalized as (
    select
        nullif(trim(unique_key), '') as raw_unique_key,
        {{ group16_integer('unique_key') }} as unique_key,
        {% if var('group16_311_has_loaded_at_utc', false) %}
        safe_cast(loaded_at_utc as timestamp) as loaded_at_utc,
        {% else %}
        cast(null as timestamp) as loaded_at_utc,
        {% endif %}
        created_date as raw_created_timestamp,
        closed_date as raw_closed_timestamp,
        {{ group16_local_datetime('created_date', timestamp_timezone, 'group16_311_timestamp_timezone') }} as created_datetime,
        {{ group16_local_datetime('closed_date', timestamp_timezone, 'group16_311_timestamp_timezone') }} as closed_datetime,
        {{ group16_borough('borough') }} as borough,
        {{ group16_zip('incident_zip') }} as zip_code,
        case upper(regexp_replace(trim(complaint_type), r'\s+', ' '))
            when 'STREET LIGHT CONDITION' then 'Street Light Condition'
            when 'TRAFFIC SIGNAL CONDITION' then 'Traffic Signal Condition'
        end as complaint_type,
        coalesce(nullif(trim(descriptor), ''), 'Not specified') as descriptor,
        nullif(trim(descriptor_2), '') as descriptor_2,
        coalesce(initcap(nullif(regexp_replace(trim(status), r'\s+', ' '), '')), 'Unknown') as status
    from {{ source('group16_raw', 'source_nyc_311_streetlight_signal') }}
),

in_scope as (
    select *
    from normalized
    where created_datetime >= datetime '2021-01-01 00:00:00'
      and created_datetime < datetime '2026-07-01 00:00:00'
      and complaint_type is not null
)

-- Filter on creation time only: a qualifying request can close after June 2026.
select
    unique_key,
    raw_unique_key,
    created_datetime,
    closed_datetime,
    date(created_datetime) as created_date,
    date(closed_datetime) as closed_date,
    cast(format_date('%Y%m%d', date(created_datetime)) as int64) as created_date_key,
    extract(hour from created_datetime) * 100 + extract(minute from created_datetime) as created_time_key,
    coalesce(cast(format_date('%Y%m%d', date(closed_datetime)) as int64), 0) as closed_date_key,
    borough,
    zip_code,
    complaint_type,
    descriptor,
    descriptor_2,
    status,
    upper(status) = 'CLOSED' as is_closed,
    1 as request_count,
    cast(round(datetime_diff(closed_datetime, created_datetime, second) / 3600.0, 2) as numeric) as resolution_hours,
    raw_created_timestamp,
    raw_closed_timestamp,
    loaded_at_utc,
    current_timestamp() as staged_at_utc
from in_scope

