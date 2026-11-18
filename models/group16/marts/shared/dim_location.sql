{{ config(materialized='table') }}

with locations as (
    select borough, zip_code from {{ ref('stg_nyc_collisions') }}
    union distinct
    select borough, zip_code from {{ ref('stg_nyc_311_requests') }}
    union distinct
    select 'Unknown' as borough, 'Unknown' as zip_code
)

select
    case
        when borough = 'Unknown' and zip_code = 'Unknown' then 0
        else farm_fingerprint(to_json_string(struct(borough, zip_code)))
    end as location_key,
    borough,
    zip_code
from locations
