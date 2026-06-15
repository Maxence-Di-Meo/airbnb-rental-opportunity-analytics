with source as (
    select * from {{ source('raw', 'tourism_supply_proxy') }}
)
select
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    {{ clean_numeric('accommodation_count') }} as accommodation_count,
    {{ clean_numeric('hotel_count') }} as hotel_count,
    {{ clean_numeric('camping_count') }} as camping_count,
    {{ clean_numeric('guest_house_count') }} as guest_house_count,
    {{ clean_numeric('holiday_village_count') }} as holiday_village_count,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file
from source

