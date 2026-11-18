{{ config(materialized='table') }}

with statuses as (
    select status from {{ ref('stg_nyc_311_requests') }}
    union distinct
    select 'Unknown' as status
)

select
    case when status = 'Unknown' then 0
         else farm_fingerprint(to_json_string(struct(status))) end as status_key,
    status,
    status = 'Closed' as is_closed
from statuses
