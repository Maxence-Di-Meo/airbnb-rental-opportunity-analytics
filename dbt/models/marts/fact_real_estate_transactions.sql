select
    transaction_id,
    date_mutation,
    code_commune as zone_id,
    code_commune,
    nom_commune,
    code_departement,
    type_local,
    valeur_fonciere,
    surface_reelle_bati,
    surface_terrain,
    price_m2_bati,
    price_m2_terrain,
    id_parcelle
from {{ ref('stg_dvf_transactions') }}
