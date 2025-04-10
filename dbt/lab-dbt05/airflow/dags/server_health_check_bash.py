# Filename: basic_server_test_dag.py
from __future__ import annotations

import pendulum

from airflow.models.dag import DAG
from airflow.operators.empty import EmptyOperator

with DAG(
    dag_id='server_health_check_empty',
    start_date=pendulum.datetime(2023, 1, 1, tz="UTC"), # Use a fixed past date
    schedule=None,                     # Run manually or based on start_date once
    catchup=False,                     # Don't run for past missed schedules
    tags=['test', 'healthcheck'],
    description='Minimal DAG using EmptyOperator to check scheduler health.',
) as dag:
    # This task does nothing but confirms the DAG can be scheduled and run.
    check_task = EmptyOperator(
        task_id='simple_check'
    )

    # Defines the task within the DAG
    check_task