from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.bash import BashOperator


PROJECT_DIR = "/opt/project"
DBT_CMD = f"dbt --project-dir {PROJECT_DIR}/dbt --profiles-dir {PROJECT_DIR}/dbt"


with DAG(
    dag_id="tourism_rental_potential_pipeline",
    start_date=datetime(2026, 1, 1),
    schedule="@monthly",
    catchup=False,
    default_args={"owner": "codex", "retries": 1},
    tags=["tourism", "rural", "investment", "dvf", "analytics"],
) as dag:
    local_to_bronze = BashOperator(
        task_id="local_to_bronze",
        bash_command=(
            f"python {PROJECT_DIR}/src/ingestion/local_to_bronze.py "
            f"--manifest {PROJECT_DIR}/config/source_manifest.yml"
        ),
    )

    bronze_to_postgres = BashOperator(
        task_id="bronze_to_postgres",
        bash_command=(
            f"python {PROJECT_DIR}/src/transform/bronze_to_postgres.py "
            f"--manifest {PROJECT_DIR}/config/source_manifest.yml"
        ),
    )

    dbt_run = BashOperator(
        task_id="dbt_run",
        bash_command=f"{DBT_CMD} run",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command=f"{DBT_CMD} test",
    )

    local_to_bronze >> bronze_to_postgres >> dbt_run >> dbt_test

