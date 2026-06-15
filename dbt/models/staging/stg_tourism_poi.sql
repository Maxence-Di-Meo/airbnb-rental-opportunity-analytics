with source as (
    select * from {{ source('raw', 'tourism_poi') }}
)
select
    md5(
        concat_ws(
            '||',
            coalesce(code_commune::text, ''),
            coalesce(poi_category::text, ''),
            coalesce(poi_label::text, ''),
            coalesce(latitude::text, ''),
            coalesce(longitude::text, ''),
            coalesce(_source_file::text, '')
        )
    ) as poi_id,
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    lower(nullif(poi_category::text, '')) as poi_category,
    lower(nullif(poi_subcategory::text, '')) as poi_subcategory,
    nullif(poi_label::text, '') as poi_label,
    cast(nullif(latitude::text, '') as numeric) as latitude,
    cast(nullif(longitude::text, '') as numeric) as longitude,
    nullif(h3_res8::text, '') as h3_res8,
    nullif(h3_res9::text, '') as h3_res9,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file
from source

