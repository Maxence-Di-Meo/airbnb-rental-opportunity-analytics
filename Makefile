PROJECT_DIR := /opt/project

.PHONY: up down logs ingest load dbt-run dbt-test dashboard

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f airflow

ingest:
	docker compose exec airflow python $(PROJECT_DIR)/src/ingestion/local_to_bronze.py --manifest $(PROJECT_DIR)/config/source_manifest.yml
	docker compose exec airflow python $(PROJECT_DIR)/src/transform/bronze_to_postgres.py --manifest $(PROJECT_DIR)/config/source_manifest.yml

dbt-run:
	docker compose exec airflow dbt run --project-dir $(PROJECT_DIR)/dbt --profiles-dir $(PROJECT_DIR)/dbt

dbt-test:
	docker compose exec airflow dbt test --project-dir $(PROJECT_DIR)/dbt --profiles-dir $(PROJECT_DIR)/dbt

dashboard:
	docker compose logs -f dashboard

