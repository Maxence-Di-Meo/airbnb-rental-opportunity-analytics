with source as (
    select * from {{ source('raw', 'mobility_access') }}
)
select
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    {{ clean_numeric('minutes_to_gare') }} as minutes_to_gare,
    {{ clean_numeric('minutes_to_motorway') }} as minutes_to_motorway,
    {{ clean_numeric('minutes_to_airport') }} as minutes_to_airport,
    {{ clean_numeric('drive_time_to_metropole') }} as drive_time_to_metropole,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file
from source

