import pendulum
from airflow import DAG
from airflow import settings
from airflow.models import Connection
from airflow.operators.bash import BashOperator
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.cncf.kubernetes.operators.pod import KubernetesPodOperator
from airflow.providers.http.operators.http import HttpOperator


# Define a DAG with the following parameters:
# - dag_id: The unique identifier for the DAG.
# - start_date: The date when the DAG should start running.
# - schedule: The schedule for the DAG. In this case, it's set to None, meaning the DAG will not run on a schedule.
# - catchup: Whether to catch up on past runs. In this case, it's set to False, meaning the DAG will not run for past dates.
def create_conn():
    session = settings.Session()
    if session.query(Connection).filter(Connection.conn_id == 'http_dummyjson').first():
        print("Connection already exists")
    else:
        new_conn = Connection(conn_id=f'http_dummyjson',
                              conn_type='http',
                              host="https://dummyjson.com/")

        session = settings.Session()
        session.add(new_conn)
        session.commit()
        print("Connection created")


with DAG(
        dag_id='operator_examples',
        start_date=pendulum.yesterday(),
        schedule=None,
        catchup=False,
        tags=['module 003', 'operators']
) as dag:
    # Define a dummy start task
    start = EmptyOperator(task_id='start')

    # Define a BashOperator task that prints a message
    bash_task = BashOperator(
        task_id='bash_task',
        bash_command='echo "Hello from Bash Operator!"'
    )


    # Define a PythonOperator task that executes a Python function
    def python_function():
        # check if connection exists and create connection if it doesn't exist
        create_conn()
        print("Hello from Python Operator!")


    python_task = PythonOperator(
        task_id='python_task',
        python_callable=python_function
    )

    # Define a SimpleHttpOperator task that makes an HTTP request
    http_task = HttpOperator(
        task_id='http_task',
        method='GET',
        http_conn_id='http_dummyjson',  # Make sure you have a connection named 'http_default'
        endpoint='/quotes',
        log_response=True
    )

    # Define a KubernetesPodOperator task that runs a container in Kubernetes
    kubernetes_task = KubernetesPodOperator(
        task_id='kubernetes_task',
        name="kubernetes_task_pod",
        namespace='default',
        image="alpine:latest",
        cmds=["echo"],
        arguments=["Hello from Kubernetes Operator!"],
    )

    # Define a dummy end task
    end = EmptyOperator(task_id='end')

    # Define the task dependencies
    start >> bash_task >> python_task >> http_task >> kubernetes_task >> end
