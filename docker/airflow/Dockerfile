FROM apache/airflow:2.9.3-python3.11

COPY docker/airflow/requirements-airflow.txt /tmp/requirements-airflow.txt
COPY docker/airflow/requirements-dbt.txt /tmp/requirements-dbt.txt

RUN pip install --no-cache-dir -r /tmp/requirements-airflow.txt \
    && python -m venv /home/airflow/dbt_venv \
    && /home/airflow/dbt_venv/bin/pip install --no-cache-dir -r /tmp/requirements-dbt.txt \
    && printf '%s\n' '#!/bin/sh' 'exec /home/airflow/dbt_venv/bin/dbt "$@"' > /home/airflow/.local/bin/dbt \
    && chmod +x /home/airflow/.local/bin/dbt

WORKDIR /opt/project
