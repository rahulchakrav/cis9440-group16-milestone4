-- Compare multiplicities per source ID, not just totals: swapped or missing
-- IDs cannot cancel each other out. Separate uniqueness tests enforce one row.
with collision_counts as (
    select collision_id, count(*) as staged_count, 0 as fact_count
    from {{ ref('stg_nyc_collisions') }} group by collision_id
    union all
    select collision_id, 0, count(*)
    from {{ ref('fact_collision') }} group by collision_id
),
request_counts as (
    select unique_key, count(*) as staged_count, 0 as fact_count
    from {{ ref('stg_nyc_311_requests') }} group by unique_key
    union all
    select unique_key, 0, count(*)
    from {{ ref('fact_311_request') }} group by unique_key
)
select 'collisions' as mart, cast(collision_id as string) as source_id,
    sum(staged_count) as staged_count, sum(fact_count) as fact_count
from collision_counts group by collision_id
having sum(staged_count) != sum(fact_count)
union all
select 'requests', cast(unique_key as string), sum(staged_count), sum(fact_count)
from request_counts group by unique_key
having sum(staged_count) != sum(fact_count)
