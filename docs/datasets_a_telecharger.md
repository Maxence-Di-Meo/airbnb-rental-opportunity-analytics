# Datasets a telecharger ou a preparer

Le projet est maintenant centre sur le **potentiel de location saisonniere rurale / touristique**, pas sur `Airbnb` comme source unique. Il te faut donc surtout des donnees territoriales et touristiques a l'echelle commune.

## Minimum a telecharger pour le MVP

### 1. DVF
Indispensable pour estimer le coût d'entree immobilier.

Range les fichiers ici:

```text
data/external/dvf/
```

Source:
- [DVF sur data.gouv.fr](https://www.data.gouv.fr/datasets/demandes-de-valeurs-foncieres/)

### 2. Tourism POI
Export structure des points d'interet touristiques ou de loisirs avec au minimum:
- `code_commune`
- `nom_commune`
- `poi_category`
- `poi_subcategory`
- `poi_label`
- `latitude`
- `longitude`

Range les fichiers ici:

```text
data/external/tourism/poi/
```

Source recommandee:
- [DATAtourisme](https://www.datatourisme.gouv.fr/)

### 3. Tourism labels
Table communale avec flags ou labels territoriaux, par exemple:
- littoral
- montagne
- lac ou plan d'eau
- parc naturel
- station classee de tourisme
- village classe / patrimoine

Colonnes minimales recommandees:
- `code_commune`
- `nom_commune`
- `is_littoral`
- `is_mountain`
- `is_lake_area`
- `is_natural_park`
- `is_classified_tourism_station`
- `is_classified_village`
- `is_heritage_village`

Range les fichiers ici:

```text
data/external/tourism/labels/
```

Sources possibles:
- [DATAtourisme](https://www.datatourisme.gouv.fr/)
- [INPN - espaces proteges](https://inpn.mnhn.fr/telechargement/cartes-et-information-geographique/espaces-proteges)
- listes officielles `communes touristiques`, `stations classees`, `parcs`

### 4. Mobility access
Table communale avec variables d'accessibilite:
- `code_commune`
- `nom_commune`
- `minutes_to_gare`
- `minutes_to_motorway`
- `minutes_to_airport`
- `drive_time_to_metropole`

Range les fichiers ici:

```text
data/external/accessibility/
```

Cette table peut etre:
- telechargee si tu trouves une source deja calculee
- ou calculee toi-meme a partir de gares, axes et moteur de routage

Sources utiles:
- [INSEE - Base permanente des equipements](https://www.insee.fr/fr/statistiques/3568638)
- [SNCF Open Data](https://ressources.data.sncf.com/)

## Fortement recommande ensuite

### 5. Seasonal population
Pour distinguer les marches stables des marches tres saisonniers.

Colonnes recommandees:
- `code_commune`
- `nom_commune`
- `seasonal_population_ratio`
- `peak_population_multiplier`

Range les fichiers ici:

```text
data/external/demography/
```

### 6. Tourism supply proxy
Pour approcher la concurrence ou la saturation du marche local.

Colonnes recommandees:
- `code_commune`
- `nom_commune`
- `accommodation_count`
- `hotel_count`
- `camping_count`
- `guest_house_count`
- `holiday_village_count`

Range les fichiers ici:

```text
data/external/tourism/supply/
```

### 7. Reference geo
Pour enrichir les libelles, departements, regions, geomettries.

Range les fichiers ici:

```text
data/external/reference/
```

## Strategie recommandee
- Commence avec `DVF + tourism_poi + tourism_labels + mobility_access`.
- Travaille au niveau **commune** pour rester robuste et realiste.
- Ajoute ensuite `seasonal_population` et `tourism_supply_proxy`.
- N'ajoute `Cadastre` que si tu veux vraiment pousser le foncier et les parcelles.

## Idee de perimetre
Pour un rendu coherent sur la campagne, cible quelques familles de territoires:
- villages littoraux
- communes de montagne
- villages proches de lacs ou de parcs naturels
- communes patrimoine / stations classees

## Point important
Certaines tables ne seront pas telechargees "telles quelles" en un seul clic. C'est normal. Pour ce projet, il est acceptable et meme pertinent de construire des **tables curées** a partir de plusieurs sources officielles, du moment que:
- tu documentes la provenance
- tu normalises les colonnes attendues
- tu gardes la reproductibilite dans le repo
