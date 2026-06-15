# AirbnbJO / Tourism Rental Analytics

Plateforme locale de data engineering / analytics issue d'un projet d'analyse des coûts et opportunités de location courte durée autour des Jeux Olympiques. La version actuelle généralise l'idée vers le scoring du potentiel d'un projet de **location saisonniere rurale et touristique** en France a partir de `DVF`, de donnees touristiques territoriales, d'accessibilite et d'attractivite geographique.

## Ce que contient ce repo
- `docker-compose.yml` pour lancer `PostGIS`, `MinIO`, `Airflow` et `Streamlit`
- `dags/` pour l'orchestration
- `src/` pour l'ingestion et le chargement raw
- `dbt/` pour les tables analytiques et le scoring
- `dashboard/streamlit_app/` pour la restitution
- `docs/` pour le cadrage et la strategie datasets

Le cadrage principal du projet est dans [cadrage_projet_location_saisonniere_rurale_touristique.md](docs/cadrage_projet_location_saisonniere_rurale_touristique.md).

## Faut-il telecharger des datasets ?
Oui. Le repo fournit le **socle technique**, pas les donnees brutes.

### Minimum viable dataset
Pour lancer un scoring rural/touristique coherent, il te faut au minimum:
- `DVF`
- un export `tourism_poi` au niveau commune ou point
- un export `tourism_labels` avec flags territoriaux
- un export `mobility_access` avec temps ou distances d'acces

### Datasets optionnels mais fortement recommandes
- `seasonal_population`
- `tourism_supply_proxy`
- `BAN / reference geo`
- `Cadastre` si tu veux pousser le volet foncier

Le detail est documente dans [datasets_a_telecharger.md](docs/datasets_a_telecharger.md).

## Arborescence attendue des fichiers source

```text
data/
  external/
    dvf/
    tourism/
      poi/
      labels/
      supply/
    accessibility/
    demography/
    reference/
    cadastre/
```

Le manifeste attendu est dans [source_manifest.yml](config/source_manifest.yml).

## Demarrage rapide

1. Lancer la stack:

```bash
docker compose up -d --build
```

2. Deposer tes fichiers dans `data/external/...`

3. Executer ingestion et transformation:

```bash
docker compose exec airflow python /opt/project/src/ingestion/local_to_bronze.py --manifest /opt/project/config/source_manifest.yml
docker compose exec airflow python /opt/project/src/transform/bronze_to_postgres.py --manifest /opt/project/config/source_manifest.yml
docker compose exec airflow dbt run --project-dir /opt/project/dbt --profiles-dir /opt/project/dbt
docker compose exec airflow dbt test --project-dir /opt/project/dbt --profiles-dir /opt/project/dbt
docker compose exec airflow pytest -q
```

4. Ouvrir les interfaces:
- Airflow: `http://localhost:8080`
- identifiants Airflow: `codex / codex`
- Streamlit: `http://localhost:8501`
- MinIO console: `http://localhost:9001`
- identifiants MinIO: `minio / minio123`

## Workflow cible
1. Tu telecharges ou prepares les exports publics `DVF`, `tourism_poi`, `tourism_labels`, `mobility_access`.
2. Le script `local_to_bronze.py` convertit les fichiers bruts en Parquet bronze et ajoute les metadonnees techniques.
3. Le script `bronze_to_postgres.py` charge les tables `raw.*`.
4. `dbt` construit les tables `staging.*`, `analytics.real_estate_zone_monthly`, `analytics.tourism_zone_features` et `analytics.location_tourism_score_latest`.
5. Le dashboard affiche un ranking de communes rurales/touristiques selon plusieurs profils investisseurs.

## Logique metier
Le projet ne cherche plus a mesurer "Airbnb reel" sur toute la France. Il estime un **potentiel locatif touristique rural** en combinant:
- coût d'entree immobilier
- attractivite naturelle et patrimoniale
- accessibilite
- intensite touristique et saisonniere
- densite d'offre concurrente

## Limites du scaffold actuel
- Le score produit un **potentiel d'investissement touristique**, pas un chiffre de revenu observe.
- Les tables `tourism_labels`, `mobility_access` et `tourism_supply_proxy` sont des **datasets structures** que tu dois preparer ou exporter proprement.
- Le niveau de sortie principal est la **commune**; si tu ajoutes des geomettries fiables, tu pourras descendre en `H3` ou en sous-zones.
- L'image `PostGIS` est forcee en `linux/amd64`; sur une machine ARM, Docker utilisera l'emulation.

## Commandes utiles

```bash
make up
make ingest
make dbt-run
make dbt-test
make dashboard
make down
```
