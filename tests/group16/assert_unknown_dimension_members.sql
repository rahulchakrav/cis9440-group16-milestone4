select 'dim_location' as model_name
from {{ ref('dim_location') }}
having countif(location_key = 0 and borough = 'Unknown' and zip_code = 'Unknown') != 1
    or countif(location_key = 0 and (borough != 'Unknown' or zip_code != 'Unknown')) > 0
union all
select 'dim_request_status'
from {{ ref('dim_request_status') }}
having countif(status_key = 0 and status = 'Unknown' and not is_closed) != 1
    or countif(status_key = 0 and status != 'Unknown') > 0
