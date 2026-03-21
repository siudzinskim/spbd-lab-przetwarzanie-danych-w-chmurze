from airflow import DAG
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup
from datetime import datetime

with DAG(
    dag_id='taskgroup_example',
    start_date=datetime(2024, 11, 4),
    schedule=None,
    catchup=False,
    tags=['module 006', 'taskgroups']
) as dag:

    with TaskGroup('extract_group') as extract_group:
        extract_task_a = BashOperator(
            task_id='extract_task_a',
            bash_command='echo "Extract A"'
        )
        extract_task_b = BashOperator(
            task_id='extract_task_b',
            bash_command='echo "Extract B"'
        )

    with TaskGroup('transform_group') as transform_group:
        transform_task = BashOperator(
            task_id='transform_task',
            bash_command='echo "Transform"'
        )

    with TaskGroup('load_group') as load_group:
        load_task = BashOperator(
            task_id='load_task',
            bash_command='echo "Load"'
        )

    extract_group >> transform_group >> load_group