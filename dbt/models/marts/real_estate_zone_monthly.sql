with base as (
    select * from {{ ref('fact_real_estate_transactions') }}
    where zone_id is not null
)
select
    zone_id,
    date_trunc('month', date_mutation)::date as month_key,
    max(nom_commune) as commune_label,
    count(*) as transaction_count,
    percentile_cont(0.5) within group (order by price_m2_bati) as median_price_m2_bati,
    percentile_cont(0.5) within group (order by price_m2_terrain) as median_price_m2_terrain,
    avg(price_m2_bati) as avg_price_m2_bati,
    stddev_samp(price_m2_bati) as stddev_price_m2_bati
from base
group by 1, 2
