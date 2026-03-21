import pendulum
from airflow.datasets import Dataset
from airflow.decorators import dag, task

# 1. Define the asset we are waiting for.
# Notice there is NO Producer DAG in Airflow for this asset!
# We are expecting an external system to notify Airflow about this URI.
EXTERNAL_SYSTEM_FLAG = Dataset("event://milestones/external_trigger")

# ==========================================
# CONSUMER DAG (Triggered by REST API)
# ==========================================
@dag(
    dag_id="consumer_external_api_flag",
    schedule=[EXTERNAL_SYSTEM_FLAG], # Waits for the API call
    start_date=pendulum.datetime(2023, 1, 1, tz="UTC"),
    catchup=False,
    tags=["demo", "assets", "consumer", "api", "module 007"]
)
def consumer_external_api_dag():

    @task
    def process_external_event():
        print("Woke up! The external system just hit the Airflow API.")
        print("I can now start my data processing without using any Sensors.")

    process_external_event()

consumer_external_api_dag()
