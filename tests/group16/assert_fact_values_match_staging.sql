-- Null-safe comparisons preserve the distinction between missing and zero.
select 'collisions' as mart, cast(s.collision_id as string) as source_id
from {{ ref('stg_nyc_collisions') }} s
join {{ ref('fact_collision') }} f on s.collision_id = f.collision_id
where f.crash_date_key is distinct from s.crash_date_key
   or f.crash_time_key is distinct from s.crash_time_key
   or f.severity_key is distinct from s.severity_key
   or f.collision_count is distinct from s.collision_count
   or f.loaded_at_utc is distinct from s.loaded_at_utc
   {% for field in ['persons', 'pedestrians', 'cyclist', 'motorist'] %}
   {% for measure in ['injured', 'killed'] %}
   or f.number_of_{{ field }}_{{ measure }} is distinct from s.number_of_{{ field }}_{{ measure }}
   {% endfor %}
   {% endfor %}
union all
select 'requests', cast(s.unique_key as string)
from {{ ref('stg_nyc_311_requests') }} s
join {{ ref('fact_311_request') }} f on s.unique_key = f.unique_key
where f.created_date_key is distinct from s.created_date_key
   or f.created_time_key is distinct from s.created_time_key
   or f.closed_date_key is distinct from s.closed_date_key
   or f.request_count is distinct from s.request_count
   or f.created_datetime is distinct from s.created_datetime
   or f.closed_datetime is distinct from s.closed_datetime
   or f.resolution_hours is distinct from s.resolution_hours
   or f.loaded_at_utc is distinct from s.loaded_at_utc
