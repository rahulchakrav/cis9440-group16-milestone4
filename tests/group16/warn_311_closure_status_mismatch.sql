{{ config(severity='warn') }}

-- Preserve the source status and closure date independently; review contradictions.
select unique_key, status, closed_datetime
from {{ ref('stg_nyc_311_requests') }}
where (is_closed and closed_datetime is null)
   or (not is_closed and closed_datetime is not null)
