{{ config(materialized='table') }}

select
    s.unique_key,
    created.date_key as created_date_key,
    t.time_key as created_time_key,
    closed.date_key as closed_date_key,
    l.location_key,
    c.complaint_key,
    r.status_key,
    s.request_count,
    s.created_datetime,
    s.closed_datetime,
    s.resolution_hours,
    s.loaded_at_utc
from {{ ref('stg_nyc_311_requests') }} as s
left join {{ ref('dim_date') }} as created
    on s.created_date_key = created.date_key
left join {{ ref('dim_date') }} as closed
    on s.closed_date_key = closed.date_key
left join {{ ref('dim_time') }} as t
    on s.created_time_key = t.time_key
left join {{ ref('dim_location') }} as l
    on s.borough = l.borough and s.zip_code = l.zip_code
left join {{ ref('dim_complaint') }} as c
    on s.complaint_type = c.complaint_type
   and s.descriptor = c.descriptor
   and s.descriptor_2 is not distinct from c.descriptor_2
left join {{ ref('dim_request_status') }} as r
    on s.status = r.status
