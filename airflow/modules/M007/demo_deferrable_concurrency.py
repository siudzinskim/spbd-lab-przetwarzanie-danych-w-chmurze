from airflow import DAG
from airflow.sensors.time_delta import TimeDeltaSensorAsync
from datetime import datetime, timedelta

with DAG(
    dag_id="demo_301_massive_parallel_deferrable",
    start_date=datetime(2023, 1, 1),
    schedule=None,
    catchup=False,
    tags=["optimization", "deferrable", "module 007"]
) as dag:

    # We launch 10 tasks in parallel.
    # Even if your worker only has 2 slots, all these will
    # 'run' and then immediately move to the Triggerer,
    # freeing up the slots for other DAGs.
    for i in range(10):
        wait_task = TimeDeltaSensorAsync(
            task_id=f"wait_task_{i}",
            delta=timedelta(minutes=2)
        )