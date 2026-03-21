from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

with DAG(
    dag_id='task_lifecycle',
    start_date=datetime.now() - timedelta(weeks=1),
    schedule=None,
    catchup=False,
    tags=['module 004', 'task lifecycle']
) as dag:

    task_a = BashOperator(
        task_id='task_a',  # This task will be renamed
        bash_command='echo "Task A"'
    )

    task_b = BashOperator(
        task_id='task_b',  # This task will be deleted
        bash_command='echo "Task B"'
    )

    task_c = BashOperator(
        task_id='task_c',
        bash_command='echo "Task C"'
    )

    task_d = BashOperator( # This task will be added
        task_id='task_d',
        bash_command='echo "Task D"'
    )

    task_a >> task_b >> task_c >> task_d

