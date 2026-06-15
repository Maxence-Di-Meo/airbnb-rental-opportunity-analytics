with poi as (
    select
        code_commune,
        max(nom_commune) as nom_commune,
        count(*) as tourism_poi_count,
        count(*) filter (
            where poi_category in ('nature', 'outdoor', 'lake', 'littoral', 'mountain', 'park', 'leisure')
        ) as nature_poi_count,
        count(*) filter (
            where poi_category in ('heritage', 'culture', 'museum', 'village', 'monument')
        ) as heritage_poi_count,
        count(*) filter (
            where poi_category in ('activity', 'wellness', 'gastronomy', 'restaurant', 'market')
        ) as amenity_poi_count
    from {{ ref('stg_tourism_poi') }}
    where code_commune is not null
    group by 1
),
labels as (
    select
        code_commune,
        max(nom_commune) as nom_commune,
        max(is_littoral) as is_littoral,
        max(is_mountain) as is_mountain,
        max(is_lake_area) as is_lake_area,
        max(is_natural_park) as is_natural_park,
        max(is_classified_tourism_station) as is_classified_tourism_station,
        max(is_classified_village) as is_classified_village,
        max(is_heritage_village) as is_heritage_village
    from {{ ref('stg_tourism_labels') }}
    where code_commune is not null
    group by 1
),
accessibility as (
    select
        code_commune,
        max(nom_commune) as nom_commune,
        min(minutes_to_gare) as minutes_to_gare,
        min(minutes_to_motorway) as minutes_to_motorway,
        min(minutes_to_airport) as minutes_to_airport,
        min(drive_time_to_metropole) as drive_time_to_metropole
    from {{ ref('stg_mobility_access') }}
    where code_commune is not null
    group by 1
),
seasonal as (
    select
        code_commune,
        max(nom_commune) as nom_commune,
        avg(seasonal_population_ratio) as seasonal_population_ratio,
        avg(peak_population_multiplier) as peak_population_multiplier
    from {{ ref('stg_seasonal_population') }}
    where code_commune is not null
    group by 1
),
supply as (
    select
        code_commune,
        max(nom_commune) as nom_commune,
        max(accommodation_count) as accommodation_count,
        max(hotel_count) as hotel_count,
        max(camping_count) as camping_count,
        max(guest_house_count) as guest_house_count,
        max(holiday_village_count) as holiday_village_count
    from {{ ref('stg_tourism_supply_proxy') }}
    where code_commune is not null
    group by 1
),
geo as (
    select
        code_commune,
        max(nom_commune) as nom_commune,
        max(code_departement) as code_departement,
        max(nom_departement) as nom_departement,
        max(nom_region) as nom_region
    from {{ ref('stg_geographic_reference') }}
    where code_commune is not null
    group by 1
)
select
    coalesce(poi.code_commune, labels.code_commune, accessibility.code_commune, seasonal.code_commune, supply.code_commune, geo.code_commune) as zone_id,
    coalesce(poi.nom_commune, labels.nom_commune, accessibility.nom_commune, seasonal.nom_commune, supply.nom_commune, geo.nom_commune) as zone_label,
    geo.code_departement,
    geo.nom_departement,
    geo.nom_region,
    coalesce(poi.tourism_poi_count, 0) as tourism_poi_count,
    coalesce(poi.nature_poi_count, 0) as nature_poi_count,
    coalesce(poi.heritage_poi_count, 0) as heritage_poi_count,
    coalesce(poi.amenity_poi_count, 0) as amenity_poi_count,
    coalesce(labels.is_littoral, 0) as is_littoral,
    coalesce(labels.is_mountain, 0) as is_mountain,
    coalesce(labels.is_lake_area, 0) as is_lake_area,
    coalesce(labels.is_natural_park, 0) as is_natural_park,
    coalesce(labels.is_classified_tourism_station, 0) as is_classified_tourism_station,
    coalesce(labels.is_classified_village, 0) as is_classified_village,
    coalesce(labels.is_heritage_village, 0) as is_heritage_village,
    accessibility.minutes_to_gare,
    accessibility.minutes_to_motorway,
    accessibility.minutes_to_airport,
    accessibility.drive_time_to_metropole,
    seasonal.seasonal_population_ratio,
    seasonal.peak_population_multiplier,
    coalesce(supply.accommodation_count, 0) as accommodation_count,
    coalesce(supply.hotel_count, 0) as hotel_count,
    coalesce(supply.camping_count, 0) as camping_count,
    coalesce(supply.guest_house_count, 0) as guest_house_count,
    coalesce(supply.holiday_village_count, 0) as holiday_village_count
from poi
full outer join labels using (code_commune)
full outer join accessibility using (code_commune)
full outer join seasonal using (code_commune)
full outer join supply using (code_commune)
full outer join geo using (code_commune)

