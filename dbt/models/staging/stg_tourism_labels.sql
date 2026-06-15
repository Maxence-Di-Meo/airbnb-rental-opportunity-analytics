with source as (
    select * from {{ source('raw', 'tourism_labels') }}
)
select
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    case when lower(coalesce(is_littoral::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_littoral,
    case when lower(coalesce(is_mountain::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_mountain,
    case when lower(coalesce(is_lake_area::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_lake_area,
    case when lower(coalesce(is_natural_park::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_natural_park,
    case when lower(coalesce(is_classified_tourism_station::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_classified_tourism_station,
    case when lower(coalesce(is_classified_village::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_classified_village,
    case when lower(coalesce(is_heritage_village::text, '')) in ('1', 'true', 't', 'yes', 'oui') then 1 else 0 end as is_heritage_village,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file
from source

