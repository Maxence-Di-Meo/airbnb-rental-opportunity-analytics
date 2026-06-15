with source as (
    select * from {{ source('raw', 'geographic_reference') }}
)
select
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    nullif(code_departement::text, '') as code_departement,
    nullif(nom_departement::text, '') as nom_departement,
    nullif(nom_region::text, '') as nom_region,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file
from source
