with source as (
    select * from {{ source('raw', 'seasonal_population') }}
)
select
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    {{ clean_numeric('seasonal_population_ratio') }} as seasonal_population_ratio,
    {{ clean_numeric('peak_population_multiplier') }} as peak_population_multiplier,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file
from source

