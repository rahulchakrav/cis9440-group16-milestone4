{{ config(materialized='table') }}

with complaints as (
    select distinct complaint_type, descriptor, descriptor_2
    from {{ ref('stg_nyc_311_requests') }}
)

-- JSON preserves nulls and field boundaries, unlike concatenated text keys.
select
    farm_fingerprint(to_json_string(struct(complaint_type, descriptor, descriptor_2))) as complaint_key,
    complaint_type,
    descriptor,
    descriptor_2
from complaints
