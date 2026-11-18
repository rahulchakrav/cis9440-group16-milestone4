select 'dim_location' as model_name, count(*) as duplicate_count
from {{ ref('dim_location') }}
group by borough, zip_code
having count(*) > 1
union all
select 'dim_complaint', count(*)
from {{ ref('dim_complaint') }}
group by complaint_type, descriptor, descriptor_2
having count(*) > 1
union all
select 'dim_request_status', count(*)
from {{ ref('dim_request_status') }}
group by status
having count(*) > 1
