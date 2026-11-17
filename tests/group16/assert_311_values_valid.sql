select unique_key, raw_unique_key, created_datetime, closed_datetime
from {{ ref('stg_nyc_311_requests') }}
where unique_key <= 0
   or closed_datetime < created_datetime
