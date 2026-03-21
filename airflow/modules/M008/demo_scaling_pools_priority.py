from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

# Define 3 levels of priority
HIGH_PRIORITY = 30
MED_PRIORITY = 20
LOW_PRIORITY = 10
BASE_SLEEP_TIME = 10

with DAG(
    dag_id="demo_322_scaling_resource_management",
    start_date=datetime(2023, 1, 1),
    schedule=None,
    catchup=False,
    tags=["scaling", "pools", "priority", "module 008"]
) as dag:

    # Group 1: Tasks A, B, C (Should start first)
    for i, task_id in enumerate(['a', 'b', 'c']):
        sleep_time = (i + 1) * BASE_SLEEP_TIME
        BashOperator(
            task_id=f"high_priority_{task_id}",
            pool="training_limited_pool",
            priority_weight=HIGH_PRIORITY,
            bash_command=f"echo 'High priority task running for {sleep_time}s'; sleep {sleep_time}"
        )

    # Group 2: Tasks D, E, F (Should start after A, B, or C finish)
    for i, task_id in enumerate(['d', 'e', 'f']):
        sleep_time = (i + 1) * BASE_SLEEP_TIME
        BashOperator(
            task_id=f"med_priority_{task_id}",
            pool="training_limited_pool",
            priority_weight=MED_PRIORITY,
            bash_command=f"echo 'Medium priority task waiting for {sleep_time}s'; sleep {sleep_time}"
        )

    # Group 3: Tasks G, H, I (Should start last)
    for i, task_id in enumerate(['g', 'h', 'i']):
        sleep_time = (i + 1) * BASE_SLEEP_TIME
        BashOperator(
            task_id=f"low_priority_{task_id}",
            pool="training_limited_pool",
            priority_weight=LOW_PRIORITY,
            bash_command=f"echo 'Low priority task waiting for {sleep_time}s'; sleep {sleep_time}"
        )