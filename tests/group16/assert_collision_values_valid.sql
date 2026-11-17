select collision_id, raw_crash_time, has_invalid_injury_count, has_invalid_crash_time
from {{ ref('stg_nyc_collisions') }}
where collision_id <= 0
   or has_invalid_injury_count
   or has_invalid_crash_time
