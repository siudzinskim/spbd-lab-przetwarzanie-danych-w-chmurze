import pendulum
from airflow.datasets import Dataset
from airflow.decorators import dag, task

# 1. Define a virtual asset (Flag/Signal)
# This URI has no physical representation on disk or in the cloud!
VIRTUAL_MILESTONE = Dataset("event://milestones/producer_task_done")

# ==========================================
# PRODUCER DAG
# ==========================================
@dag(
    dag_id="producer_virtual_flag",
    schedule=None,
    start_date=pendulum.datetime(2023, 1, 1, tz="UTC"),
    catchup=False,
    tags=["demo", "assets", "producer", "module 007"]
)
def producer_virtual_dag():

    # This task simply finishes execution and emits a signal
    @task(outlets=[VIRTUAL_MILESTONE])
    def run_heavy_computation():
        print("Performing complex in-memory computations (without saving to a file)...")
        print("Done! Raising the virtual flag 'producer_task_done'.")

    run_heavy_computation()

producer_virtual_dag()


# ==========================================
# CONSUMER DAG
# ==========================================
@dag(
    dag_id="consumer_virtual_flag",
    schedule=[VIRTUAL_MILESTONE], # Waiting for our logical flag
    start_date=pendulum.datetime(2023, 1, 1, tz="UTC"),
    catchup=False,
    tags=["demo", "assets", "consumer", "module 007"]
)
def consumer_virtual_dag():

    @task
    def react_to_event():
        print("Registered that the virtual asset (flag) has been updated!")
        print("No need to look for any file. I'm just starting my part of the job.")

    react_to_event()

consumer_virtual_dag()