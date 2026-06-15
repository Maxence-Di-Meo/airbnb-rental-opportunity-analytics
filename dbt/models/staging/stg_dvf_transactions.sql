with source as (
    select * from {{ source('raw', 'dvf_mutations') }}
)
select
    md5(
        concat_ws(
            '||',
            coalesce(date_mutation::text, ''),
            coalesce(valeur_fonciere::text, ''),
            coalesce(code_commune::text, ''),
            coalesce(nom_commune::text, ''),
            coalesce(id_parcelle::text, ''),
            coalesce(_source_file::text, '')
        )
    ) as transaction_id,
    case
        when date_mutation::text ~ '^\d{4}-\d{2}-\d{2}$' then to_date(date_mutation::text, 'YYYY-MM-DD')
        when date_mutation::text ~ '^\d{2}/\d{2}/\d{4}$' then to_date(date_mutation::text, 'DD/MM/YYYY')
        else null
    end as date_mutation,
    nullif(nature_mutation::text, '') as nature_mutation,
    {{ clean_numeric('valeur_fonciere') }} as valeur_fonciere,
    nullif(code_postal::text, '') as code_postal,
    nullif(code_commune::text, '') as code_commune,
    nullif(nom_commune::text, '') as nom_commune,
    nullif(code_departement::text, '') as code_departement,
    nullif(type_local::text, '') as type_local,
    {{ clean_numeric('surface_reelle_bati') }} as surface_reelle_bati,
    {{ clean_numeric('surface_terrain') }} as surface_terrain,
    cast(nullif(nombre_pieces_principales::text, '') as integer) as nombre_pieces_principales,
    cast(nullif(longitude::text, '') as numeric) as longitude,
    cast(nullif(latitude::text, '') as numeric) as latitude,
    nullif(h3_res8::text, '') as h3_res8,
    nullif(h3_res9::text, '') as h3_res9,
    nullif(id_parcelle::text, '') as id_parcelle,
    cast(nullif(_snapshot_date::text, '') as date) as snapshot_date,
    _source_file,
    case
        when {{ clean_numeric('surface_reelle_bati') }} > 0 then {{ clean_numeric('valeur_fonciere') }} / {{ clean_numeric('surface_reelle_bati') }}
        else null
    end as price_m2_bati,
    case
        when {{ clean_numeric('surface_terrain') }} > 0 then {{ clean_numeric('valeur_fonciere') }} / {{ clean_numeric('surface_terrain') }}
        else null
    end as price_m2_terrain
from source
