with real_estate_latest_month as (
    select max(month_key) as month_key
    from {{ ref('real_estate_zone_monthly') }}
),
real_estate_latest as (
    select *
    from {{ ref('real_estate_zone_monthly') }}
    where month_key = (select month_key from real_estate_latest_month)
),
joined as (
    select
        coalesce(r.zone_id, t.zone_id) as zone_id,
        coalesce(t.zone_label, r.commune_label, coalesce(r.zone_id, t.zone_id)) as zone_label,
        r.month_key as real_estate_month_key,
        r.transaction_count,
        r.median_price_m2_bati,
        r.median_price_m2_terrain,
        t.code_departement,
        t.nom_departement,
        t.nom_region,
        t.tourism_poi_count,
        t.nature_poi_count,
        t.heritage_poi_count,
        t.amenity_poi_count,
        t.is_littoral,
        t.is_mountain,
        t.is_lake_area,
        t.is_natural_park,
        t.is_classified_tourism_station,
        t.is_classified_village,
        t.is_heritage_village,
        t.minutes_to_gare,
        t.minutes_to_motorway,
        t.minutes_to_airport,
        t.drive_time_to_metropole,
        t.seasonal_population_ratio,
        t.peak_population_multiplier,
        t.accommodation_count,
        t.hotel_count,
        t.camping_count,
        t.guest_house_count,
        t.holiday_village_count
    from real_estate_latest r
    full outer join {{ ref('tourism_zone_features') }} t
        on r.zone_id = t.zone_id
),
metrics as (
    select
        *,
        coalesce(median_price_m2_bati, median_price_m2_terrain, 0) * 60 as benchmark_entry_ticket_est,
        (
            1.30 * coalesce(nature_poi_count, 0) +
            1.10 * coalesce(heritage_poi_count, 0) +
            0.60 * coalesce(amenity_poi_count, 0) +
            8.00 * coalesce(is_littoral, 0) +
            8.00 * coalesce(is_mountain, 0) +
            6.00 * coalesce(is_lake_area, 0) +
            6.00 * coalesce(is_natural_park, 0) +
            5.00 * coalesce(is_classified_tourism_station, 0) +
            4.00 * coalesce(is_classified_village, 0) +
            3.00 * coalesce(is_heritage_village, 0)
        ) as attractiveness_raw,
        (
            3.00 * coalesce(is_littoral, 0) +
            3.00 * coalesce(is_mountain, 0) +
            2.00 * coalesce(is_lake_area, 0) +
            2.00 * coalesce(is_natural_park, 0) +
            1.50 * coalesce(is_classified_village, 0) +
            0.50 * coalesce(nature_poi_count, 0)
        ) as nature_raw,
        (
            1 / (1 + coalesce(minutes_to_gare, 999) / 30.0) +
            1 / (1 + coalesce(minutes_to_motorway, 999) / 20.0) +
            1 / (1 + coalesce(minutes_to_airport, 999) / 60.0) +
            1 / (1 + coalesce(drive_time_to_metropole, 999) / 90.0)
        ) as access_raw,
        coalesce(peak_population_multiplier, seasonal_population_ratio, 1.0) as seasonality_intensity,
        case
            when coalesce(peak_population_multiplier, seasonal_population_ratio, 1.0) > 0
                then 1 / coalesce(peak_population_multiplier, seasonal_population_ratio, 1.0)
            else null
        end as stability_raw,
        greatest(
            coalesce(accommodation_count, 0),
            coalesce(hotel_count, 0) + coalesce(camping_count, 0) + coalesce(guest_house_count, 0) + coalesce(holiday_village_count, 0)
        ) as competition_raw
    from joined
),
normalized as (
    select
        *,
        (attractiveness_raw - min(attractiveness_raw) over ()) / nullif(max(attractiveness_raw) over () - min(attractiveness_raw) over (), 0) as attractiveness_norm,
        (nature_raw - min(nature_raw) over ()) / nullif(max(nature_raw) over () - min(nature_raw) over (), 0) as nature_norm,
        (access_raw - min(access_raw) over ()) / nullif(max(access_raw) over () - min(access_raw) over (), 0) as access_norm,
        (seasonality_intensity - min(seasonality_intensity) over ()) / nullif(max(seasonality_intensity) over () - min(seasonality_intensity) over (), 0) as seasonality_norm,
        (coalesce(stability_raw, 0) - min(coalesce(stability_raw, 0)) over ()) / nullif(max(coalesce(stability_raw, 0)) over () - min(coalesce(stability_raw, 0)) over (), 0) as stability_norm,
        (benchmark_entry_ticket_est - min(benchmark_entry_ticket_est) over ()) / nullif(max(benchmark_entry_ticket_est) over () - min(benchmark_entry_ticket_est) over (), 0) as cost_norm,
        (competition_raw - min(competition_raw) over ()) / nullif(max(competition_raw) over () - min(competition_raw) over (), 0) as competition_norm
    from metrics
),
scored as (
    select
        zone_id,
        zone_label,
        real_estate_month_key,
        code_departement,
        nom_departement,
        nom_region,
        transaction_count,
        median_price_m2_bati,
        median_price_m2_terrain,
        benchmark_entry_ticket_est,
        tourism_poi_count,
        nature_poi_count,
        heritage_poi_count,
        amenity_poi_count,
        is_littoral,
        is_mountain,
        is_lake_area,
        is_natural_park,
        is_classified_tourism_station,
        is_classified_village,
        is_heritage_village,
        minutes_to_gare,
        minutes_to_motorway,
        minutes_to_airport,
        drive_time_to_metropole,
        seasonality_intensity,
        competition_raw as competition_proxy,
        attractiveness_raw as tourism_potential_proxy,
        nature_raw as nature_score,
        access_raw as access_score,
        coalesce(stability_raw, 0) as stability_score,
        round(100 * (
            0.25 * coalesce(attractiveness_norm, 0) +
            0.20 * coalesce(access_norm, 0) +
            0.25 * coalesce(stability_norm, 0) -
            0.20 * coalesce(cost_norm, 0) -
            0.10 * coalesce(competition_norm, 0)
        ), 2) as score_prudent,
        round(100 * (
            0.35 * coalesce(attractiveness_norm, 0) +
            0.20 * coalesce(access_norm, 0) +
            0.10 * coalesce(seasonality_norm, 0) -
            0.20 * coalesce(cost_norm, 0) -
            0.15 * coalesce(competition_norm, 0)
        ), 2) as score_rendement,
        round(100 * (
            0.35 * coalesce(nature_norm, 0) +
            0.20 * coalesce(attractiveness_norm, 0) +
            0.15 * coalesce(access_norm, 0) -
            0.10 * coalesce(cost_norm, 0) -
            0.10 * coalesce(competition_norm, 0)
        ), 2) as score_nature_premium,
        round(100 * (
            0.40 * (1 - coalesce(cost_norm, 0)) +
            0.20 * coalesce(access_norm, 0) +
            0.20 * coalesce(attractiveness_norm, 0) +
            0.10 * coalesce(stability_norm, 0) -
            0.10 * coalesce(competition_norm, 0)
        ), 2) as score_petit_budget
    from normalized
)
select *
from scored
where zone_id is not null
