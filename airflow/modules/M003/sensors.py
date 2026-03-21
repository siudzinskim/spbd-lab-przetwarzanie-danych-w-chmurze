# /home/marcin/dev/airflow-training/airflow-training/modules/M003/sensors.py

import pendulum
from airflow import DAG
from airflow import settings
from airflow.models import Connection
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.sensors.filesystem import FileSensor


def create_conn():
    session = settings.Session()
    if session.query(Connection).filter(Connection.conn_id == 'fs_default').first():
        print("Connection already exists")
    else:
        new_conn = Connection(conn_id=f'fs_default',
                              conn_type='fs')

        session = settings.Session()
        session.add(new_conn)
        session.commit()
        print("Connection created")


# DAG that waits for the file and triggers another DAG
with DAG(
        dag_id='file_sensor_dag',
        start_date=pendulum.yesterday(),
        schedule=None,  # No scheduled run, trigger manually or via API
        catchup=False,
        tags=['module 003', 'sensors']
) as dag:
    # Define a start task creating connection if it does not exist
    start = PythonOperator(
        task_id='start',
        python_callable=create_conn
    )

    # Define a FileSensor task that waits for a file to exist
    wait_for_file = FileSensor(
        task_id='wait_for_file',
        filepath='/tmp/myfile.txt'
    )

    # Define a TriggerDagRunOperator task that triggers another DAG
    trigger_file_creator_dag = TriggerDagRunOperator(
        task_id='trigger_file_creator_dag',
        trigger_dag_id='file_creator_dag',  # This is the ID of the second DAG
        wait_for_completion=False  # Don't wait for the second DAG to finish
    )

    # Define a BashOperator task that processes the file
    process_file = BashOperator(
        task_id='process_file',
        bash_command='echo "File arrived and processed!"'
    )

    # Define a BashOperator task that removes the file after processing
    remove_file = BashOperator(
        task_id='remove_file',
        bash_command='rm /tmp/myfile.txt'
    )

    # Define a dummy end task
    end = EmptyOperator(task_id='end')

    # Define the task dependencies
    start >> [wait_for_file, trigger_file_creator_dag]
    wait_for_file >> process_file >> remove_file >> end

    ## Verify what will happen if you change the tasks dependencies to following:
    # start >> [wait_for_file, trigger_file_creator_dag] >> wait_for_file >> process_file >> remove_file >> end

# DAG that creates the file after a delay
with DAG(
        dag_id='file_creator_dag',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 003', 'sensors']
) as dag:
    # Define a BashOperator task that waits for 120 seconds
    wait = BashOperator(
        task_id='wait',
        bash_command='sleep 120'  # Wait for 120 seconds
    )

    # Define a BashOperator task that creates the file
    create_file = BashOperator(
        task_id='create_file',
        bash_command='touch /tmp/myfile.txt'  # Create the file
    )

    # Define the task dependencies
    wait >> create_file
